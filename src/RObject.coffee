do ->
  factory = (EventEmitter) ->
    class RObject extends EventEmitter
      constructor: (val, opts={}) ->
        # About refs:
        # refs contain the RObject by property or array index
        # once a ref is added it never changes so for example
        # when an array item is spliced in a way that shifts items
        # down in the array, the refs will stay the same and will not
        # be shifted, their values will be updated to the new values
        # at their relevant indexes
        @_propRefs = {}
        @_arrayRefs = {}
        @set val

      value: ->
        switch @_type
          when 'array'
            for item, i in @_val
              if @_arrayRefs[i]
                @_val[i] = @_arrayRefs[i].value()
          when 'object'
            for own name of @_val
              if @_propRefs[name]
                @_val[name] = @_propRefs[name].value()

        @_val

      # toObject: ->
      #   switch @_type
      #     when 'array'
      #       for item in @_val
      #         item.toObject()
      #     when 'object'
      #       result = {}
      #       #todo: for own of?
      #       for own key, val of @_val
      #         result[key] = if val.toObject then val.toObject() else val
      #       result
      #     else
      #       @value()

      type: ->
        # needs to be created lazily since we can't create a new RObject in the constructor
        @_rtype or= new RObject @_type

      length: ->
        @_rlength or= new RObject @_val?.length

      set: (val) ->
        val = null if val == undefined # undefined is translated to null

        return this if @_val == val # don't fire change event for the same value
        previousValue = @_val
        previousType = @_type
        @_val = val

        @_type = RObject.typeFromNative @_val
        @_rtype?.set @_type

        switch @_type
          when 'array'
            #todo: is this length change fired too soon?
            @_rlength?.set @_val.length
            for value, i in @_val
              if @_arrayRefs[i]
                @_arrayRefs[i].set value

          when 'string'
            @_rlength?.set @_val.length

          when 'object'
            for own name, value of @_val
              if @_propRefs[name]
                @_propRefs[name].set value
                # @_val[name] = @_propRefs[name]
              # else
              #   throw new Error('aa') if value instanceof RObject
              #   @_propRefs[name] = new RObject(value)

        # we need to keep the refs around but just empty them
        for name, ref of @_propRefs
          if previousType == 'object' && !@_val?[name]?
            ref.set null

        @emit 'change'
        this

      prop: (name, value) ->
        if arguments.length > 1
          # set property to value
          prop = @prop(name).set value
          @_val[name] = prop
          return prop

        @_propRefs[name] or= new RObject(@_val?[name])

      at: (index) ->
        @_arrayRefs[index] or= new RObject(@_val[index])


      #   child = new RObject()
      #   update = =>
      #     child.set switch @_type
      #       when 'array'
      #         @_val[index.value()].value()
      #       else
      #         null

      #   @on 'add', update
      #   @on 'remove', update
      #   index.on 'change', update
      #   update()

      #   child

      combine: (operands..., handler) ->
        child = new RObject()
        cb = =>
          operandValues = (operand.value() for operand in operands)
          child.set handler this.value(), operandValues...
        this.on 'change', cb
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

      splice: (index, numToRemove, itemsToAdd...) ->
        switch @_type
          when 'array'
            removed = @_val.splice index, numToRemove, itemsToAdd...

            for i, ref of @_arrayRefs
              ref.set @_val[i]

            @_rlength?.set @_val.length

            if removed.length
              @emit 'remove', removed, {index}

            if itemsToAdd.length
              @emit 'add', itemsToAdd, {index}

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


      # map: (transform) ->
      #   child = new RObject()
      #   update = =>
      #     child.set switch @_type
      #       when 'array'
      #         @_val.map transform
      #       else
      #         null

      #   # assume add and remove are only called when type is array
      #   @on 'remove', (items, {index}) ->
      #     child.splice index, items.length

      #   @on 'add', (items, {index}) ->
      #     #todo: handle multiple added
      #     result = transform items[0]
      #     rResult = if result instanceof RObject then result else new RObject(result)
      #     child.add rResult, {index}

      #   @on 'change', update
      #   update()

      #   child

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
      indexOf: (operand) ->
        switch @_type
          when 'string'
            @combine operand, (aVal, bVal) ->
              aVal.indexOf bVal
          else
            @ #todo: return invalid or 0 or something?



    RObject.typeFromNative = (object) ->
      if object == null || object == undefined
        'empty'
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
