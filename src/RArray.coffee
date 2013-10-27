
RType = require './RType'
RNumber = require './RNumber'

class RArray extends RType
  constructor: ->
    super
    @_val or= []
    @length = new RNumber(@_val.length)

  add: (items, opts) ->
    index = opts?.at ? @_val.length
    if Array.isArray items
      @splice index, 0, items...
    else
      @splice index, 0, items

  splice: (index, numToRemove, itemsToAdd...) ->
    removed = @_val.splice index, numToRemove, itemsToAdd...
    @length.set @_val.length

    if removed.length
      itemOrItemsRemoved = if removed.length == 1 then removed[0] else removed
      @emit 'remove', itemOrItemsRemoved, {index}

    if itemsToAdd.length
      itemOrItemsToAdd = if itemsToAdd.length == 1 then itemsToAdd[0] else itemsToAdd
      @emit 'add', itemOrItemsToAdd, {index}


  filter: (passFail) ->
    constructArr = for item in @_val
      if passFail(item).value()
        item
      else
        continue

    child = new RArray constructArr

    @on 'add', (items, {index}) =>
      items = [items] if !Array.isArray items

      # find the nearest preceding item in parent that is also in child
      parentIndex = index

      while (childIndex = child._val.indexOf(@_val[parentIndex])) == -1    # child._val
        --parentIndex

        if parentIndex <= 0
          break

      passing = for item in items
        if passFail(item).value()
          item
        else
          continue

      child.add passing, at: childIndex + 1

    return child



  map: (transform) ->
    child = new RArray @_val.map transform
    # @on 'remove'

    @on 'add', (item) ->
      child.add transform(item)

    return child

  toObject: ->
    for item in @_val
      item.toObject()

module.exports = RArray
