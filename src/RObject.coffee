do ->
  factory = (EventEmitter) ->

    class RObject extends EventEmitter
      constructor: (val, opts={}) ->
        @set val

      value: ->
        @_val

      toObject: ->
        switch @_type
          when 'array'
            for item in @_val
              item.toObject()
          when 'object'
            result = {}
            for key, val of @_val
              result[key] = if val.toObject then val.toObject() else val
            result
          else
            @value()

      type: ->
        # needs to be created lazily since we can't create a new RObject in the constructor
        @_rtype or= new RObject @_type

      length: ->
        @_rlength or= new RObject @_val?.length

      set: (val) ->
        throw new Error('Cannot set read only object') if @_readOnly

        val = null if val == undefined # undefined is translated to null

        return this if @_val == val # don't fire change event for the same value
        @_val = val

        @_type = RObject.typeFromNative @_val
        @_rtype?.set @_type

        switch @_type
          when 'array'
            @_rlength?.set @_val.length
            for o, i in @_val
              if o not instanceof RObject
                @_val[i] = new RObject o

          when 'string'
            @_rlength?.set @_val.length

        @emit 'change'
        this

      prop: (name, value) ->

        # maybe changes to the parent RObject should be fired as a change on this

        if arguments.length > 1
          # set property to value
          @prop(name).set value

        else
          # need to make a new child to return because when the type of
          #  this changes to/from a type 'object' we need to change to/from
          #  the value of that property, so we do that by turning on and off
          #  a proxy from the actual property to the return of this

          child = new RObject()

          update = =>
            switch @_type
              when 'object'
                if @_val[name] not instanceof RObject
                  @_val[name] = new RObject(@_val[name])

                source = @_val[name]
                lock = false

                updateChild = =>
                  return if lock
                  lock = true
                  child.set source.value()
                  lock = false

                updateParent = =>
                  return if lock
                  lock = true
                  source.set child.value()
                  lock = false

                source.on 'change', updateChild
                child.on 'change', updateParent

                updateChild()

              else
                child.set null, disableProxy: true

          @on 'change', update
          update()

          child


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
            index = opts?.at ? @_val.length
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
            @_rlength?.set @_val.length

            if removed.length
              itemOrItemsRemoved = if removed.length == 1 then removed[0] else removed
              @emit 'remove', itemOrItemsRemoved, {index}

            if itemsToAdd.length
              itemOrItemsToAdd = if itemsToAdd.length == 1 then itemsToAdd[0] else itemsToAdd
              @emit 'add', itemOrItemsToAdd, {index}

          #todo string
          else
            @

      filter: (passFail) ->
        child = new RObject()

        addToChild = (items, {index, noListen}) =>
          items = [items] if !Array.isArray items

          # find the nearest preceding item in parent that is also in child
          parentIndex = index
          while (childIndex = child.value().indexOf(@_val[parentIndex])) == -1
            --parentIndex

            if parentIndex < 0
              break

          passing = for item, i in items
            passes = passFail item
            updatee = do (i, passes, item) =>
              =>
                # console.log @_val.indexOf(item)
                if passes.value()
                  addToChild item, index: index + i, noListen: true
                else
                  removeFromChild item, index: index + i


            passes.on 'change', updatee if !noListen

            if passes.value()
              item
            else
              continue

          if passing.length
            child.add passing, at: childIndex + 1


        removeFromChild = (items, {index}) =>
          items = [items] if !Array.isArray items

          # find the index of the first item removed (if any) that is also in child
          removedIndex = 0
          while (childIndex = child.value().indexOf(items[removedIndex])) == -1
            ++removedIndex

            if removedIndex >= items.length
              # none of the removed items were in child, nothing to do
              return

          # now removedIndex is the index of the first item in items that was in child
          #  and childIndex is the index of that item in child
          # we now need to start removing items
          #  keeping in mind not all items are in child so we may have to skip some

          while removedIndex < items.length && childIndex < child.value().length
            match = items[removedIndex] == child.value()[childIndex]

            if match
              child.splice childIndex, 1
              ++removedIndex
            else
              ++childIndex

        update = =>
          switch @_type
            when 'array'
              child.set []
              # for item in @_val
              #   if passFail(item).value()
              #     item
              #   else
              #     continue
              addToChild @_val, index: 0
            else
              child.set null


        @on 'add', addToChild
        @on 'remove', removeFromChild

        @on 'change', update
        update()

        child


      map: (transform) ->
        child = new RObject()
        update = =>
          child.set switch @_type
            when 'array'
              @_val.map transform
            else
              null

        # assume add and remove are only called when type is array
        @on 'remove', (item, {index}) ->
          numRemoved = if Array.isArray(item) then item.length else 1
          child.splice index, numRemoved

        @on 'add', (item) ->
          child.add transform(item)

        @on 'change', update
        update()

        child


      at: (index) ->
        child = new RObject()
        update = =>
          child.set switch @_type
            when 'array'
              @_val[index.value()].value()
            else
              null

        @on 'add', update
        @on 'remove', update
        index.on 'change', update
        update()

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

      indexOf: (operand) ->
        switch @_type
          when 'array', 'string'
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
