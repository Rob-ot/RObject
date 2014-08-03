do ->
  id = 0

  factory = (EventEmitter) ->
    class RObject extends EventEmitter
      constructor: (val, opts={}) ->

        # rCache is the lazily created vivified version of _val
        # when _sync is called its values are synced back to _val
        # its contents are wiped when _val is changed
        # it is spliced upon when _val is spliced
        @_rCache = []

        # _ats[0] contains an RObject that always contains the value at index 0
        # these are lazily filled and updated over time to always represent the
        # values at each relevant position or location
        @_ats = []

        # for objects _props is used as both rCache and _ats since there is
        # never any splicing happening
        @_props = {}

        @_id = id++

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
              if @_rCache[i]?
                @_val[i] = @_rCache[i].value()
          when 'object'
            for own name of @_val
              if @_props[name]?
                @_val[name] = @_props[name].value()

      type: ->
        # needs to be created lazily since we can't create a new RObject in the constructor
        @_rtype or= new RObject(if @_type is 'proxy' then @_val.type() else @_type)

      refType: ->
        @_rRefType or= new RObject @_type

      length: ->
        @_rlength or= new RObject if @_val instanceof RObject
          @_val.length()
        else
          @_val?.length

      refSet: (val) ->
        if @ == val
          throw new Error "bad (refSet)"

        val = null if val == undefined # undefined is translated to null

        # if RObject.typeFromNative(val) == 'proxy'
        #   console.log 'setting', @_id, 's value to ', val._id

        return this if @_val == val # don't fire change event for the same value

        previousValue = @_val
        previousType = @_type
        @_val = val

        if previousType == 'proxy'
          previousValue.off 'change', @_emitChange

        @_rCache = []

        @_type = RObject.typeFromNative @_val
        @_rRefType?.set @_type
        @_rtype?.set if @_type is 'proxy' then @_val.type() else @_type

        #todo: is this length change fired too soon?
        @_rlength?.refSet switch @_type
          when 'array', 'string'
            @_val.length
          when 'proxy'
            @_val.length()
          else
            null

        switch @_type
          when 'array'
            for value, i in @_val
              if @_rCache[i]
                @_rCache[i].set value
              else if value instanceof RObject
                @_rCache[i] = value

            @_refreshAts()

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
            @_val.on 'change', @_emitChange

        # we need to keep the empty props references around but just empty them
        switch previousType
          when 'object'
            for name, prop of @_props
              if !@_val?[name]?
                prop.set null

          when 'array'
            @_refreshAts()

        @emit 'change'
        this

      _emitChange: =>
        @emit 'change'

      set: (val) ->
        if @ == val
          throw new Error "bad"

        if @_type == 'proxy'
          return @_val.set val

        @refSet val

      #todo: optimize out this fn and run only on indexes that change
      _refreshAts: ->
        switch @_type
          when 'array'
            for i in [0..@_val.length]
              if @_ats[i]
                @_ats[i].refSet @_rCache[i] || @_val[i]

          else
            # null everything out
            for at, i in @_ats
              if at
                at.refSet null


      prop: (key) ->
        child = new RObject()
        update = =>
          if @_type is 'proxy'
            return child.refSet @_val.prop key

          keyVal = if key instanceof RObject then key.value() else key

          if typeof keyVal is 'string'
            @_props[keyVal] or= new RObject(@_val?[keyVal])

            # mark this property in _val to make sure it will be iterated over in _sync
            # would it be better to iterate through a combined and uniqued
            # list of _val keys and _props keys?
            if @_type is 'object' && @_val[keyVal] == undefined
              @_val[keyVal] = undefined

            switch @_type
              when 'object'
                child.refSet @_props[keyVal]
              else
                child.refSet null
          else
            child.refSet null

        @on 'change', update
        if key instanceof RObject
          key.on 'change', update
        update()
        child

      #todo: optimize - dont use an extra proxy when index is static?
      at: (index) ->
        child = new RObject()
        update = =>
          if @_type is 'proxy'
            return child.refSet @_val.at index

          indexVal = if index instanceof RObject then index.value() else index
          # it is important that elements in _ats are proxied to the item in _rCache at index
          val = if @_type == 'array' then @_val[indexVal] else null

          if typeof indexVal is 'number'
            @_rCache[indexVal] or= new RObject()
            #todo: how to handle nested RObject properly?
            @_rCache[indexVal].refSet(val) if @_rCache[indexVal] != val
            @_ats[indexVal] or= new RObject(@_rCache[indexVal])

          switch @_type
            when 'array'
              #todo: what does this do?
              @_val[indexVal] = @_rCache[indexVal]

              child.refSet @_ats[indexVal]
            else
              child.refSet null

        @on 'change', update
        if index instanceof RObject
          index.on 'change', update
        update()
        child

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

            # since _rCache is sparse, make sure index exists so splice works properly
            @_rCache[index] ?= undefined

            rRemoved = @_rCache.splice index, numToRemove, rItemsToAdd...

            # _rCache is lazily created so make sure the things we just spliced off are RObjects
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

          when 'proxy'
            @_val.splice.apply @_val, arguments
          #todo string
          else
            @

      _vivifyAll: ->
        return if @_type != 'array' || !@_val.length
        @_vivifySpan 0, @_val.length - 1

      _vivifySpan: (index, howMany) ->
        return if @_type != 'array'
        for i in [index..howMany]
          @_rCache[i] or= new RObject(@_val[i])

        null




      combine: (operands..., handler) ->
        child = new RObject()
        cb = =>
          operandValues = (operand.value() for operand in operands)
          child.set handler @value(), operandValues...
        @on 'change', cb
        for operand in operands
          operand.on 'change', cb
        cb()
        return child

      # executes cb with @value() immediately and anytime this changes
      # watch: (cb) ->
      #   run = =>
      #     cb @value()
      #   @on 'change', run
      #   run()

      inverse: ->
        @combine (value) =>
          switch @type().value()
            when 'boolean'
              !value
            when 'number'
              -value
            else
              value


      # add: (items, opts) ->
      #   #todo: consider renaming to just push, I don't like that this is a mutator or a getter fn
      #   #todo: handle adding non-number types
      #   switch @_type
      #     when 'array'
      #       index = opts?.index ? @_val.length
      #       if Array.isArray items
      #         @splice index, 0, items...
      #       else
      #         @splice index, 0, items

      #     when 'number'
      #       @combine items, (aVal, bVal) ->
      #         aVal + bVal
      #     else
      #       @


      # filter: (passFail) ->

      #   child = new RObject()
      #   passChangeHandlers = []

      #   # self = this
      #   # passings = @map (value) ->
      #   #   passFail value

      #   # # handleAdd = ->
      #   # #   console.log 'handleAdd', @

      #   # #todo: use subscribe here?
      #   # passings.on 'add', (passesGroup) ->
      #   #   for passes in passesGroup
      #   #     passes.on 'change', handleAdd

      #   # passings.reduce (prev, current, index) ->

      #   # # a 1:1 mapping of this value to child indexes
      #   # # we need to (quickly) know where to insert items in the child
      #   # # with just a parent id, we use this to look those up
      #   # # childIndexes[parentIndex] == childIndex of that item or null
      #   # childIndexes = []


      #   addToChild = (items, {index, noListen}) =>
      #     # starting at location the items were added,
      #     # find the nearest preceding item in parent that is also in child
      #     parentIndex = index - 1
      #     #todo: this needs to be searching for an instance not a value
      #     while (childIndex = child.value().indexOf(@_val[parentIndex])) == -1
      #       parentIndex--
      #       if parentIndex < 0
      #         break

      #     passing = for item, i in items
      #       passes = passFail item
      #       updatee = do (i, passes, item) =>
      #         =>
      #           if passes.value()
      #             addToChild [item], index: index + i, noListen: true
      #           else
      #             removeFromChild [item], index: index + i

      #       #todo: test noListen
      #       passes.on 'change', updatee if !noListen
      #       # console.log 'set passChangeHandler', index + i
      #       passChangeHandlers.splice index + i, 0, [passes, updatee]

      #       if passes.value()
      #         item
      #       else
      #         continue

      #     if passing.length
      #       child.splice childIndex + 1, 0, passing...


      #   removeFromChild = (items, {index}) =>
      #     # find my index of the first item removed (if any) that is also in child
      #     removedIndex = 0
      #     #todo: is it okay to assume child.elements is vivified? we shouldn't reach into child
      #     while (childIndex = child._rCache.indexOf(items[removedIndex])) == -1
      #       ++removedIndex

      #       if removedIndex >= items.length
      #         # none of the removed items were in child, nothing to do
      #         return

      #     # now removedIndex is my index of the first item that is in child
      #     #  and childIndex is childs index of that item
      #     # we now start removing items
      #     #  keeping in mind not all items are in child so we may have to skip some

      #     while removedIndex < items.length && childIndex < child._rCache.length
      #       match = items[removedIndex] == child._rCache[childIndex]

      #       if match
      #         # console.log 'removeFromChild', child[childIndex]
      #         child.splice childIndex, 1
      #         [passes, updatee] = passChangeHandlers[childIndex]
      #         # passes.off 'change', updatee
      #         passChangeHandlers.splice childIndex, 1
      #         # console.log 'removing passChangeHandler', childIndex

      #         ++removedIndex
      #       else
      #         ++childIndex

      #   change = =>
      #     while passChangeHandler = passChangeHandlers.pop()
      #       passChangeHandler[0].off 'change', passChangeHandler[1]
      #     switch @_type
      #       when 'array'
      #         child.set [] #todo: test and fix double change of child
      #         @_vivifyAll()
      #         addToChild @_rCache, index: 0
      #       else
      #         child.set null

      #   @on 'add', addToChild
      #   @on 'remove', removeFromChild

      #   @on 'change', change
      #   change()

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
        reset = =>
          child.set switch @_type
            when 'array'
              for item, i in @_val
                transform @_rCache[i] or= new RObject(@_val[i])
            else
              null

        @on 'remove', (items, {index}) ->
          child.splice index, items.length

        @on 'add', (items, {index}) ->
          transformed = for item in items
            result = transform item
            if result instanceof RObject then result else new RObject(result)

          child.splice index, 0, transformed...

        @on 'change', reset
        reset()

        child


      subtract: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal - bVal

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

      is: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal == bVal

      # negate: ->
      #   @combine RNumber, (val) ->
      #     -val

      #todo: enforce string types?
      concat: (operand) ->
        @combine operand, (aVal, bVal) ->
          aVal + bVal

      #todo: make work on arrays
      # indexOf: (operand) ->
      #   # how do we handle passed in RObjects?! check by value or ref?
      #   @combine operand, (aVal, bVal) =>
      #     switch @type().value()
      #       when 'string'
      #         aVal.indexOf bVal
      #       when 'array'
      #         -1
      #       else
      #         -1

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
