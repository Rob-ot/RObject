do ->
  factory = (EventEmitter) ->
    class RObject extends EventEmitter
      constructor: (val, opts={}) ->

        # About _props and _elements:
        # _props and _elements contain the RObject by property or array index
        # once a prop or element is added it never changes so for example
        # when an array item is spliced in a way that shifts items
        # down in the array, _elements will stay the same and will not
        # be shifted, their values will be updated to the new values
        # at their relevant indexes
        @_props = {}

        # _elements is a 1:1 lazy mapping of @_value converted to RObjects
        # when items are spliced in or out of @_val they are also spliced on @_elements
        @_elements = []
        # _ats is a lazy storage for RObjects that hold the live value of elements
        # at the given offset
        # when items are spliced in or out of @_val _ats don't move around,
        # their values are just updated to the new value at given offset
        @_ats = []

        @set val

      value: ->
        if @_val instanceof RObject
          @_val.value()
        else
          @_sync()
          @_val

      refValue: ->
        @_sync()
        @_val

      _sync: ->
        switch @_type
          when 'array'
            for item, i in @_val
              if @_elements[i]
                @_val[i] = @_elements[i].value()
          when 'object'
            for own name of @_val
              if @_props[name]
                @_val[name] = @_props[name].value()

      type: ->
        # needs to be created lazily since we can't create a new RObject in the constructor
        @_rtype or= new RObject(if @_type is 'proxy' then @_val.type() else @_type)

      refType: ->
        @_rRefType or= new RObject @_type

      length: ->
        @_rlength or= new RObject @_val?.length

      refSet: (val) ->
        val = null if val == undefined # undefined is translated to null

        return this if @_val == val # don't fire change event for the same value

        previousValue = @_val
        previousType = @_type
        @_val = val

        @_type = RObject.typeFromNative @_val
        @_rRefType?.set @_type
        @_rtype?.set if @_type is 'proxy' then @_val.type() else @_type

        switch @_type
          when 'array'
            #todo: is this length change fired too soon?
            @_rlength?.set @_val.length
            for value, i in @_val
              if @_elements[i]
                @_elements[i].set value
              else if value instanceof RObject
                @_elements[i] = value

          when 'string'
            @_rlength?.set @_val.length

          when 'object'
            for own name, value of @_val
              if @_props[name]
                @_props[name].set value
              else if value instanceof RObject
                # if set is called with an RObject as a property
                # and its _props[name] is not set yet
                # we can just use that same RObject
                @_props[name] = value


          when 'proxy'
            @_val.on 'change', =>
              @emit 'change'

        @_refreshAts()

        # we need to keep the empty props references around but just empty them
        for name, prop of @_props
          if previousType == 'object' && !@_val?[name]?
            prop.set null
        #todo: this for arrays?

        @emit 'change'
        this

      set: (val) ->
        return @_val.set val if @_type == 'proxy'
        @refSet val

      #todo: optimize out this fn and run only on indexes that change
      _refreshAts: ->
        switch @_type
          when 'array'
            for i in [0..@_val.length]
              if @_ats[i]
                @_ats[i].refSet @_elements[i] || @_val[i]

          else
            # null everything out
            for at, i in @_ats
              if at
                at.refSet null


      prop: (name, value) ->
        if arguments.length > 1
          prop = @prop(name).set value
          return prop

        child = new RObject()
        update = =>
          nameVal = if name instanceof RObject then name.value() else name
          @_props[nameVal] or= new RObject(@_val?[nameVal])
          if @_type is 'object'
            @_val[nameVal] = @_props[nameVal]
          child.refSet @_props[nameVal]

        if name instanceof RObject
          name.on 'change', update
        update()
        child

      #todo: optimize - dont use an extra proxy when index is static
      at: (index) ->
        child = new RObject()
        update = =>
          indexVal = if index instanceof RObject then index.value() else index
          # it is important that elements in _ats are proxied to the item in _elements at index
          @_ats[indexVal] or= new RObject(
            @_elements[indexVal] or= new RObject(@_val[indexVal])
          )

          #todo: what does this do?
          if @_type is 'array'
            @_val[indexVal] = @_elements[indexVal]
          child.refSet @_ats[indexVal]

        if index instanceof RObject
          index.on 'change', update
        update()
        child

      combine: (operands..., handler) ->
        child = new RObject()
        cb = =>
          operandValues = (operand.value() for operand in operands)
          child.set handler @_val, operandValues...
        @on 'change', cb
        for operand in operands
          operand.on 'change', cb
        cb()
        return child

      # executes cb with @value() immediately and anytime this changes
      watch: (cb) ->
        run = =>
          cb @value()
        @on 'change', run
        run()

      inverse: ->
        @combine (value) =>
          switch @_type
            when 'boolean'
              !value
            when 'number'
              -value
            else
              value


      add: (items, opts) ->
        #todo: consider renaming to just push, I don't like that this is a mutator or a getter fn
        #todo: handle adding non-number types
        switch @_type
          when 'array'
            index = opts?.index ? @_val.length
            if Array.isArray items
              @splice index, 0, items...
            else
              @splice index, 0, items

          when 'number'
            @combine items, (aVal, bVal) ->
              aVal + bVal
          else
            @

      splice: (index, requestedNumToRemove, itemsToAdd...) ->
        switch @_type
          when 'array'
            removeHangover = index + requestedNumToRemove - @_val.length
            numToRemove = if removeHangover > 0
              requestedNumToRemove - removeHangover
            else
              requestedNumToRemove


            rItemsToAdd = for item, i in itemsToAdd
              if item instanceof RObject then item else new RObject(item)

            # since _elements is sparse, make sure index exists so splice works properly
            @_elements[index] ?= undefined

            rRemoved = @_elements.splice index, numToRemove, rItemsToAdd...

            # _elements is lazily created so make sure the things we just spliced off are RObjects
            if numToRemove
              for i in [0..numToRemove - 1]
                rRemoved[i] or= new RObject(@_val[index + i])

            removed = @_val.splice index, numToRemove, itemsToAdd...

            @_rlength?.set @_val.length

            @_refreshAts()

            if rRemoved.length
              @emit 'remove', rRemoved, {index}

            if itemsToAdd.length
              @emit 'add', rItemsToAdd, {index}

            removed
          #todo string
          else
            @

      # filter: (passFail) ->
      #   child = new RObject()

      #   addToChild = (items, {index, noListen}) =>
      #     # find the nearest preceding item in parent that is also in child
      #     parentIndex = index
      #     while (childIndex = child.value().indexOf(@_val[parentIndex])) == -1
      #       --parentIndex

      #       if parentIndex < 0
      #         break

      #     passing = for item, i in items
      #       passes = passFail item
      #       updatee = do (i, passes, item) =>
      #         =>
      #           # console.log @_val.indexOf(item)
      #           if passes.value()
      #             addToChild [item], index: index + i, noListen: true
      #           else
      #             removeFromChild [item], index: index + i


      #       passes.on 'change', updatee if !noListen

      #       if passes.value()
      #         item
      #       else
      #         continue

      #     if passing.length
      #       child.add passing, index: childIndex + 1


      #   removeFromChild = (items, {index}) =>
      #     # find the index of the first item removed (if any) that is also in child
      #     removedIndex = 0
      #     while (childIndex = child.value().indexOf(items[removedIndex])) == -1
      #       ++removedIndex

      #       if removedIndex >= items.length
      #         # none of the removed items were in child, nothing to do
      #         return

      #     # now removedIndex is the index of the first item in items that was in child
      #     #  and childIndex is the index of that item in child
      #     # we now need to start removing items
      #     #  keeping in mind not all items are in child so we may have to skip some

      #     while removedIndex < items.length && childIndex < child.value().length
      #       match = items[removedIndex] == child.value()[childIndex]

      #       if match
      #         child.splice childIndex, 1
      #         ++removedIndex
      #       else
      #         ++childIndex

      #   update = =>
      #     switch @_type
      #       when 'array'
      #         child.set []
      #         # for item in @_val
      #         #   if passFail(item).value()
      #         #     item
      #         #   else
      #         #     continue
      #         addToChild @_val, index: 0
      #       else
      #         child.set null


      #   @on 'add', addToChild
      #   @on 'remove', removeFromChild

      #   @on 'change', update
      #   update()

      #   child


      # reduce: (reducer, initial) ->
      #   child = new RObject()

      #   if arguments.length == 1
      #     initial = new RObject()

      #   listeners = []

      #   reReduce = =>
      #     for listener in listeners
      #       listener.target.off listener.event, listener.handler

      #     child.set @_val.reduce(->
      #       result = reducer arguments...
      #       result.on 'change', reReduce
      #       listeners.push target: result, event: 'change', handler: reReduce
      #       result
      #     , initial).value()

      #   update = =>
      #     switch @_type
      #       when 'array'
      #         @on 'add', reReduce
      #         @on 'remove', reReduce
      #         reReduce()
      #       else
      #         child.set null

      #   @on 'change', update
      #   update()

      #   child


      map: (transform) ->
        child = new RObject()
        update = =>
          child.set switch @_type
            when 'array'
              for item, i in @_val
                transform @_elements[i] or= new RObject(@_val[i])
            else
              null

        @on 'remove', (items, {index}) ->
          child.splice index, items.length

        @on 'add', (items, {index}) ->
          transformed = for item in items
            result = transform item
            if result instanceof RObject then result else new RObject(result)

          child.splice index, 0, transformed...

        @on 'change', update
        update()

        child

      # subscribe: (handler) ->
      #   update = =>
      #     if @_type == 'array'
      #       for item, index in @_val
      #         handler item, {index}

      #   @on 'add', (added, {index}) ->
      #     for item, i in added
      #       handler item, {index: index + i}

      #   @on 'change', update
      #   update()

      # subtract: (operand) ->
      #   @combine operand, (aVal, bVal) ->
      #     aVal - bVal

      multiply: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal * bVal

      divide: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal / bVal

      mod: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal % bVal

      greaterThan: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal > bVal

      greaterThanOrEqual: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal >= bVal

      lessThan: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal < bVal

      lessThanOrEqual: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal <= bVal

      # is: (operand) ->
      #   @combine operand, (aVal, bVal) ->
      #     aVal == bVal

      # negate: ->
      #   @combine RNumber, (val) ->
      #     -val

      #todo: enforce string types?
      concat: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal + bVal

      #todo: make work on arrays
      indexOf: (operand) ->
        switch @_type
          when 'string'
            @combine operand, (aVal, bVal) ->
              aVal.indexOf bVal
          else
            @ #todo: return invalid or 0 or something?

    # for own method, original of RObject.prototype
    #   continue if method in ['constructor', 'value', 'combine', '_refreshAts', 'prop', 'splice', 'refValue', 'at', 'type', 'refType', 'refSet', 'set', 'inverse', '_sync', 'map']
    #   do (method, original) ->
    #     RObject.prototype[method] = ->
    #       child = new RObject()
    #       originalArguments = arguments
    #       update = ->
    #         child.refSet if @_type == 'proxy'
    #           @_val[method].apply @_val, originalArguments
    #         else
    #           original.apply @, originalArguments

    #       @on 'change', update
    #       # for argument in arguments
    #       #   if argument instanceof RObject
    #       #     argument.on 'change', ->
    #       #       console.log 'arg changed'
    #       #       update()
    #       update.call @

    #       child

    RObject.typeFromNative = (object) ->
      if object == null || object == undefined
        'empty'
      else if object instanceof RObject
        'proxy'
      else if Array.isArray(object)
        'array'
      else
        typeof object

    return RObject


  if typeof define == 'function' && define.amd
    define ['./EventEmitter'], (EventEmitter) ->
      factory EventEmitter

  else if typeof module == 'object' && module.exports
    EventEmitter = require './EventEmitter'
    module.exports = factory EventEmitter

  else
    window.RObject = factory window.EventEmitter
