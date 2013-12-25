
assert = require 'assert'

RObject = require '../src/RObject'

#todo: test empty cases and stuff

# everything that returns an RObject should handle type changes of self

# #watch()

# test length

types = [
  'empty'
  'empty'
  'boolean'
  'number'
  'number'
  'string'
  'string'
  'object'
  'object'
  'array'
  'array'
]

typeValues = [
  undefined
  null
  true
  0
  7
  ''
  'bbq'
  {}
  {a: 'b'}
  []
  [8]
]

# to test every edge case it's a good idea to make sure things
#  work no matter what the previous state of the RObject was
# run the fn for every possible type and set type
everyType = (fn) ->
  # straight instantiated with the value
  for typeValue, i in typeValues
    fn new RObject(typeValue), types[i], typeValue

  # set to value later
  for typeValue in typeValues
    for setValue, i in typeValues
      fn new RObject(typeValue).set(setValue), types[i], setValue

everyTypeExcept = (blacklist, fn) ->
  everyType (result, type, value) =>
    if type != blacklist
      fn result, type, value

#todo: make sure length and type are correct when change event is fired
describe '#set()', ->
  it 'should not fire change event when set to the same value', ->
    o = new RObject()
    o.on 'change', -> changes++
    for val in typeValues
      o.set val
      changes = 0
      o.set val
      assert.equal changes, 0

  it 'should update length when value changes to an array', ->
    everyType (o) ->
      changeLength = null
      o.on 'change', ->
        changeLength = o.length().value()
      o.set [1, 2, 3, 4, 5]

      assert.equal changeLength, 5
      assert.equal o.length().value(), 5

  it 'should update length when value changes to a string', ->
    everyType (o) ->
      changeLength = null
      o.on 'change', ->
        changeLength = o.length().value()
      o.set 'bqebaqueue'
      assert.equal changeLength, 10
      assert.equal o.length().value(), 10

describe '#type()', ->
  it 'should detect the type based on what is passed in', ->
    assert.equal new RObject(8).type().value(), 'number'
    assert.equal new RObject('8').type().value(), 'string'
    assert.equal new RObject(true).type().value(), 'boolean'
    assert.equal new RObject(null).type().value(), 'empty'
    assert.equal new RObject(undefined).type().value(), 'empty'
    assert.equal new RObject({}).type().value(), 'object'
    assert.equal new RObject([]).type().value(), 'array'

  it 'should update type when value changes dynamically', ->
    everyType (update) ->
      o = new RObject(12)
      changeType = 'asdf'
      o.on 'change', ->
        changeType = o.type().value()

      o.set update.value()
      assert.equal changeType, update.type().value()
      assert.equal o.type().value(), update.type().value()

describe '#value()', ->
  it 'should return the same item rObject was created with', ->
    for item in [8, '8', true, null]
      assert.strictEqual new RObject(item).value(), item

  it 'should modify object passed in', ->
    original = {a: 'aee'}
    o = new RObject(original)
    o.prop 'a', 'lol'
    o.prop 'b', 'bbq'
    assert.equal original.a.value(), 'lol'
    assert.strictEqual original.b.value(), 'bbq'

  it 'should translate undefined to null', ->
    assert.strictEqual new RObject(null).value(), null
    assert.strictEqual new RObject(undefined).value(), null

  it 'should only convert to native object shallow', ->
    assert.equal new RObject({ five: new RObject(5) }).value().five instanceof RObject, true
    assert.equal new RObject({ five: new RObject(5) }).value().five.value(), 5
    assert.equal new RObject([ new RObject(5) ]).value()[0] instanceof RObject, true
    assert.equal new RObject([ new RObject(5) ]).value()[0].value(), 5

  it 'should give value of values added later', ->
    o = new RObject({})
    o.prop('cat', 'mouse')
    assert.equal o.value().cat.value(), 'mouse'

    o = new RObject([])
    o.splice 0, 0, new RObject(4)
    assert.equal o.value()[0].value(), 4

describe '#toObject()', ->
  it 'should give native value for simple types', ->
    assert.strictEqual new RObject('foo').toObject(), 'foo'
    assert.strictEqual new RObject(6).toObject(), 6
    assert.strictEqual new RObject(true).toObject(), true

  it 'should give native value for arrays and their contents', ->
    complex = new RObject([
      new RObject('foo')
      new RObject(6)
      new RObject(true)
      new RObject([3])
      new RObject({
        one: 1
        two: new RObject('2')
        more: new RObject({
          a: new RObject('aee')
          b: 'bee'
        })
      })
    ])
    assert.deepEqual complex.toObject(), [
      'foo'
      6
      true
      [3]
      {
        one: '1'
        two: '2'
        more: {
          a: 'aee'
          b: 'bee'
        }
      }
    ]

  it 'should give native value for items that have had a property accessed', ->
    o = new RObject({ d: false })
    o.prop 'd'
    assert.deepEqual o.toObject(), { d: false }

describe '#inverse()', ->
  describe 'type: boolean', ->
    it 'should inverse value', ->
      o = new RObject(false)
      inverse = o.inverse()
      assert.strictEqual inverse.value(), true
      o.set true
      assert.strictEqual inverse.value(), false

  describe 'type: number', ->
    it 'should inverse', ->
      o = new RObject(8)
      inverse = o.inverse()
      assert.strictEqual inverse.value(), -8
      o.set -8
      assert.strictEqual inverse.value(), 8

  describe 'type: other', ->
    it 'should noop', ->
      o = new RObject('8')
      inverse = o.inverse()
      assert.strictEqual inverse.value(), '8'

  it 'should handle dynamic type change', ->
    o = new RObject(false)
    inverse = o.inverse()
    assert.strictEqual inverse.value(), true
    o.set 3
    assert.strictEqual inverse.value(), -3
    o.set null
    assert.strictEqual inverse.value(), null

# make sure all methods work with multi-adds/removes
# make sure all methods handle when values change
# edge case, called with empty and stuff

describe '#splice()', ->
  nums = for i in [0..10]
    new RObject i

  o = new RObject([])
  o.splice 0, 0, nums[0], nums[1]
  assert.deepEqual o.toObject(), [0, 1]

  it 'should add to beginning', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      assert.deepEqual items, [nums[2]]
      assert.strictEqual index, 0
      addCalls++
    remove = (items, {index}) ->
      removeCalls++

    o.on 'add', add
    o.on 'remove', remove

    o.splice 0, 0, nums[2]
    assert.deepEqual o.toObject(), [2, 0, 1]
    assert.equal addCalls, 1
    assert.equal removeCalls, 0

    o.removeListener 'add', add
    o.removeListener 'remove', remove

  it 'should add to end', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      assert.deepEqual items, [nums[3]]
      assert.strictEqual index, 3
      addCalls++
    remove = (items, {index}) ->
      removeCalls++

    o.on 'add', add
    o.on 'remove', remove

    o.splice 3, 0, nums[3]
    assert.deepEqual o.toObject(), [2, 0, 1, 3]
    assert.equal addCalls, 1
    assert.equal removeCalls, 0

    o.removeListener 'add', add
    o.removeListener 'remove', remove

  it 'should remove 1 at index', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      addCalls++
    remove = (items, {index}) ->
      assert.deepEqual items, [nums[0]]
      assert.strictEqual index, 1
      removeCalls++

    o.on 'add', add
    o.on 'remove', remove

    removed = o.splice 1, 1
    assert.deepEqual o.toObject(), [2, 1, 3]
    # assert.deepEqual removed, []
    assert.equal addCalls, 0
    assert.equal removeCalls, 1

    o.removeListener 'add', add
    o.removeListener 'remove', remove

  it 'should remove and add at the index', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      assert.deepEqual items, [nums[4], nums[5], nums[6], nums[7]]
      assert.strictEqual index, 1
      assert.equal removeCalls, 1, 'remove event should be fired before add event'
      addCalls++
    remove = (items, {index}) ->
      assert.deepEqual items[0], nums[1]
      assert.strictEqual index, 1
      removeCalls++

    o.on 'add', add
    o.on 'remove', remove

    o.splice 1, 1, nums[4], nums[5], nums[6], nums[7]
    assert.deepEqual o.toObject(), [2, 4, 5, 6, 7, 3]
    assert.equal addCalls, 1
    assert.equal removeCalls, 1

    o.removeListener 'add', add
    o.removeListener 'remove', remove

  it 'should remove all', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      addCalls++
    remove = (items, {index}) ->
      assert.deepEqual items, [nums[2], nums[4], nums[5], nums[6], nums[7], nums[3]]
      assert.strictEqual index, 0
      removeCalls++

    o.on 'add', add
    o.on 'remove', remove

    o.splice 0, 6
    assert.deepEqual o.toObject(), []
    assert.equal addCalls, 0
    assert.equal removeCalls, 1

    o.removeListener 'add', add
    o.removeListener 'remove', remove

  it 'should fire with the actual number of items removed when splice is called with more', ->
    o = new RObject([1, 2, 3])
    removed = []
    removedIndex = null
    o.on 'remove', (items, {index}) ->
      removed.push items
      removedIndex = index

    o.splice 1, 12

    assert.equal removed.length, 1
    assert.equal removedIndex, 1
    assert.equal removed[0].length, 2

  it 'should not fire any events when splice is called with no changes', ->
    o = new RObject([1, 2, 3])

    removed = []
    o.on 'remove', (items) ->
      removed.push items

    added = []
    o.on 'add', (items) ->
      added.push items

    o.splice 1, 0

    assert.equal removed.length, 0
    assert.equal added.length, 0

  #todo: change events
  #todo: negative number indexes
  #todo: edge cases
  #todo: returns items removed

#todo: rerun fn if an RObject wasnt returned?
describe '#map()', ->
  inverse = (item) ->
    item.inverse()

  describe 'type: Array', ->
    it 'should map initial items', ->
      o = new RObject([1, 2])
      inversed = o.map inverse
      assert.deepEqual inversed.value().map((i) -> i.value()), [-1, -2]

    it 'should map items added later', ->
      o = new RObject([1])
      inversed = o.map inverse
      o.add new RObject(2)
      assert.deepEqual inversed.toObject(), [-1, -2]

    it 'should remove items from the child when items are removed from the parent', ->
      o = new RObject([1, 2, 3])
      inversed = o.map inverse
      o.splice 1, 1

      assert.deepEqual inversed.toObject(), [-1, -3]

    it 'should maintain order of added items', ->
      o = new RObject([1, 3])
      inversed = o.map inverse
      o.splice 1, 0, new RObject(2)
      assert.deepEqual inversed.toObject(), [-1, -2, -3]

    it 'should only call transform fn once when item is added', ->
      o = new RObject([1])
      transforms = 0
      inversed = o.map (item) ->
        transforms++
        item.inverse()

      transforms = 0
      o.add new RObject(2)
      assert.equal transforms, 1

    it 'should update when parent value changes and not rerun transform fn', ->
      cbs = 0
      num = new RObject(1)
      o = new RObject([num])
      inversed = o.map (item) ->
        cbs++
        item.inverse()

      num.set(2)
      assert.deepEqual inversed.toObject(), [-2]
      assert.equal cbs, 1

    it 'should make returned values into RObjects and trigger add event with it', ->
      o = new RObject([1, 3])

      inversed = o.map (item) ->
        assert.equal item instanceof RObject, true
        -item.value()

      added = []
      inversed.on 'add', (items) ->
        added.push items

      o.add new RObject(2)

      assert.equal inversed.length().value(), 3
      for item, i in inversed
        assert.equal item instanceof RObject, true
        assert.equal item.value(), -(i + 1)

      assert.equal added.length, 1
      assert.equal added[0][0] instanceof RObject, true


  describe 'type: Other', ->
    it 'should return null', ->
      o = new RObject()
      inversed = o.map inverse

      assert.deepEqual inversed.value(), null

  it 'should handle dynamic type change', ->
    o = new RObject()
    inversed = o.map (item) ->
      item.inverse()

    o.set [3]
    assert.deepEqual inversed.toObject(), [-3]
    o.set null
    assert.deepEqual inversed.value(), null



describe '#filter()', ->
  isEven = (num) ->
    num.mod(new RObject(2)).is(new RObject(0))

  describe 'type: Array', ->
    it 'should filter initial items', ->
      o = new RObject([4, 5, 6])
      evens = o.filter isEven
      assert.deepEqual evens.toObject(), [4, 6]

    it 'should filter added items', ->
      o = new RObject([4, 5, 6])
      evens = o.filter isEven
      o.add new RObject(7)
      assert.deepEqual evens.toObject(), [4, 6]
      o.add new RObject(8)
      assert.deepEqual evens.toObject(), [4, 6, 8]

    it 'should filter added items when more than one is added at a time', ->
      o = new RObject([4, 5, 6])
      evens = o.filter isEven
      o.add [new RObject(7), new RObject(8)]
      assert.deepEqual evens.toObject(), [4, 6, 8]

    it 'should filter added items and put them in the correct place when spliced', ->
      o = new RObject([1, 2, 4, 3, 3, 5, 9, 12])
      evens = o.filter isEven
      o.splice 5, 0, new RObject(7), new RObject(8), new RObject(9), new RObject(10)
      assert.deepEqual evens.toObject(), [2, 4, 8, 10, 12]

    it 'should filter added items and put them in the correct place when spliced at position 0', ->
      o = new RObject([3, 4])
      evens = o.filter isEven
      o.splice 0, 0, new RObject(2)
      assert.deepEqual evens.toObject(), [2, 4]

    it 'should remove items that are removed from the source', ->
      source = new RObject([
        new RObject(3)
        new RObject(4)
        new RObject(3) # remove
        new RObject(8) # remove
        new RObject(2) # remove
        new RObject(5)
        new RObject(6)
      ])
      evens = source.filter isEven
      source.splice 2, 3
      assert.deepEqual evens.toObject(), [4, 6]

    it 'should always call back with an RObject', ->
      o = new RObject([3])
      isRObject = false
      evens = o.filter (val) ->
        isRObject = val instanceof RObject
        new RObject(true)

      assert.equal isRObject, true

    it 'should update filter when given boolean changes', ->
      first = new RObject(3)
      o = new RObject([first])
      evens = o.filter isEven
      first.set 4
      assert.deepEqual evens.toObject(), [4]
      first.set 3
      assert.deepEqual evens.toObject(), []

    it 'should update filter when given boolean changes for dynamically added items', ->
      four = new RObject(4)
      o = new RObject([2, 3, 5, 6])
      evens = o.filter isEven
      o.splice 2, 0, four
      four.set 4
      assert.deepEqual evens.toObject(), [2, 4, 6]
      four.set 3
      assert.deepEqual evens.toObject(), [2, 6]
      # do it again to make sure it is releasing event listeners and stuff
      four.set 4
      assert.deepEqual evens.toObject(), [2, 4, 6]
      four.set 3
      assert.deepEqual evens.toObject(), [2, 6]

    it 'should maintain order of filtered arrays', ->
      o = new RObject([1, 2, 3, 4, 5, 6])
      evens = o.filter isEven
      o.value()[3].set 11
      o.value()[3].set 4
      assert.deepEqual evens.toObject(), [2, 4, 6]


  it 'should handle dynamic type change', ->
    o = new RObject()
    evens = o.filter isEven
    o.set [3, 4]
    assert.deepEqual evens.toObject(), [4]
    o.set null
    assert.deepEqual evens.toObject(), null


#todo: test event listener removal
describe '#reduce()', ->
  add = (prev, current) ->
    prev.add current

  describe 'type: Array', ->
    it 'should run through items and give the result', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce (prev, current) ->
        if prev.type().value() == 'empty'
          prev.set 0
        prev.add current
      assert.equal result.value(), 10

    it 'should run through items and give the result starting with given inital value', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(8)
      assert.equal result.value(), 18

    it 'should run through items and give the result starting with given inital value', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(0)
      assert.equal result.value(), 10

    it 'should update reduced value when item is added to array', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(0)
      o.splice 1, 0, new RObject(37)
      assert.equal result.value(), 47

    it 'should update reduced value when multiple items are added to array', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(0)
      o.splice 1, 0, new RObject(37), new RObject(74), new RObject(86)
      assert.equal result.value(), 207

    it 'should update reduced value when item is removed from array', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(0)
      o.splice 1, 1
      assert.equal result.value(), 8

    it 'should update reduced value when multiple items are removed from array', ->
      o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(0)
      o.splice 1, 2
      assert.equal result.value(), 5

    it 'should update reduced value when items change', ->
      val = new RObject(2)
      o = new RObject([ new RObject(1), val, new RObject(3), new RObject(4) ])
      result = o.reduce add, new RObject(0)
      val.set 39
      assert.equal result.value(), 47

    it 'should update reduced value when given a subproperty', ->
      o = new RObject([
        new RObject({ name: 'JJ' })
        new RObject({ name: 'John' })
        new RObject({ name: 'Johan' })
        new RObject({ name: 'Jackie' })
      ])
      result = o.reduce (prev, current) ->
        prev.add current.prop('name').length()
      , new RObject(0)
      assert.equal result.value(), 17

    it 'should update reduced value when given subproperty changes', ->
      name = new RObject 'John'
      o = new RObject([
        new RObject({ name: 'JJ' })
        new RObject({ name: name })
        new RObject({ name: 'Johan' })
        new RObject({ name: 'Jackie' })
      ])
      result = o.reduce (prev, current) ->
        prev.add current.prop('name').length()
      , new RObject(0)
      name.set 'Johnathan'
      assert.equal result.value(), 22

  describe 'type: Other', ->
    everyTypeExcept 'array', (o) ->
      result = o.reduce ->
      assert.equal result.value(), null


describe '#subscribe()', ->
  describe 'type: Array', ->
    it 'should call fn for every item that is already in the array', ->
      o = new RObject([1, 2, 3])
      calls = []
      o.subscribe (item) ->
        calls.push item

      assert.equal calls.length, 3
      assert.deepEqual (calls.map((o) -> o.toObject())), [1, 2, 3]

    it 'should call fn for items dynamically added', ->
      o = new RObject([])
      calls = []
      o.subscribe (item) ->
        calls.push item

      o.splice 0, 0, new RObject(1), new RObject(2), new RObject(3)

      assert.equal calls.length, 3
      assert.deepEqual (calls.map((o) -> o.toObject())), [1, 2, 3]

    it 'should include indexes of items added', ->
      o = new RObject([1, 2, 4, 5])
      calls = []
      indexes = []
      o.subscribe (item, {index}) ->
        calls.push item
        indexes.push index

      o.splice 1, 1, new RObject(2), new RObject(3)

      assert.equal calls.length, 6
      assert.deepEqual (calls.map((o) -> o.toObject())), [1, 2, 4, 5, 2, 3]
      assert.deepEqual indexes, [0, 1, 2, 3, 1, 2]

    it 'should call fn when type is dynamically changed to an array', ->
      everyTypeExcept 'array', (o) ->
        calls = []
        indexes = []
        o.subscribe (item, {index}) ->
          calls.push item
          indexes.push index

        o.set [1, 2]
        assert.equal calls.length, 2
        assert.deepEqual indexes, [0, 1]

    it 'should call fn when type is dynamically changed to array from another array', ->
      o = new RObject([1, 2])

      calls = []
      indexes = []
      o.subscribe (item, {index}) ->
        calls.push item
        indexes.push index

      assert.equal calls.length, 2

      o.set [3, 4]

      assert.deepEqual calls.map((o) -> o.toObject()), [1, 2, 3, 4]
      assert.deepEqual indexes, [0, 1, 0, 1]

  describe 'type: Other', ->
    it 'should never call fn unless type is array', ->
      everyTypeExcept 'array', (other) ->
        o = new RObject
        calls = 0
        o.subscribe ->
          calls++
        o.set other
        assert.equal calls, 0


describe '#add()', ->
  it 'should add item and trigger add event', ->
    o = new RObject([])
    one = new RObject(1)
    addTriggered = false
    o.on 'add', (items, {index}) ->
      assert.strictEqual items[0], one, 'add event should include added item'
      assert.strictEqual o.length().value(), 1, 'array length should be updated by the time add event is triggered'
      assert.strictEqual index, 0, 'add event should include index'
      addTriggered = true

    o.add one
    assert.equal addTriggered, true
    assert.deepEqual o.value(), [one]

  it 'should add at the index if one is specified', ->
    o = new RObject([5, 6, 7])
    one = new RObject(1)
    addTriggered = false
    o.on 'add', (items, {index}) ->
      assert.strictEqual items[0], one, 'add event should include added item'
      assert.strictEqual o.length().value(), 4, 'array length should be updated by the time add event is triggered'
      assert.strictEqual index, 2, 'add event should include index'
      addTriggered = true

    o.add one, {index: 2}
    assert.equal addTriggered, true
    assert.deepEqual o.toObject(), [5, 6, 1, 7]

  it 'should allow adding multiple items via Array', ->
    o = new RObject([3, 8, 9])
    addsTriggered = 0
    four = new RObject(4)
    five = new RObject(5)
    six = new RObject(6)
    seven = new RObject(7)
    o.on 'add', (items, {index}) ->
      assert.deepEqual items, [four, five, six, seven], 'add event should include added items'
      assert.strictEqual o.length().value(), 7, 'array length should be updated by the time add event is triggered'
      assert.strictEqual index, 1, 'add event should include index'
      addsTriggered++

    o.add [four, five, six, seven], {index: 1}
    assert.deepEqual o.toObject(), [3, 4, 5, 6, 7, 8, 9]
    assert.equal addsTriggered, 1

describe '#add()', ->
  o1 = new RObject(5)
  o2 = new RObject(6)
  result = o1.add(o2)
  assert.strictEqual result.value(), 11
  o1.set 12
  assert.strictEqual result.value(), 18, "it should update when first value is changed"
  o2.set 33
  assert.strictEqual result.value(), 45, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#subtract()', ->
  o1 = new RObject(5)
  o2 = new RObject(6)
  result = o1.subtract(o2)
  assert.strictEqual result.value(), -1, "it should subtract the initial values"
  o1.set 12
  assert.strictEqual result.value(), 6, "it should update when first value is changed"
  o2.set 33
  assert.strictEqual result.value(), -21, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#multiply()', ->
  o1 = new RObject(5)
  o2 = new RObject(6)
  result = o1.multiply(o2)
  assert.strictEqual result.value(), 30, "it should multiply the initial values"
  o1.set 12
  assert.strictEqual result.value(), 72, "it should update when first value is changed"
  o2.set 33
  assert.strictEqual result.value(), 396, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#divide()', ->
  o1 = new RObject(-12)
  o2 = new RObject(6)
  result = o1.divide(o2)
  assert.strictEqual result.value(), -2, "it should divide the initial values"
  o1.set 36
  assert.strictEqual result.value(), 6, "it should update when first value is changed"
  o2.set 3
  assert.strictEqual result.value(), 12, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"

  it 'should be Infinity when dividing by 0', ->
    result = new RObject(12).divide(new RObject(0))
    assert.equal result.value(), Infinity


describe '#mod()', ->
  o1 = new RObject(1046)
  o2 = new RObject(100)
  result = o1.mod(o2)
  assert.strictEqual result.value(), 46, "it should mod the initial values"
  o1.set 1073
  assert.strictEqual result.value(), 73, "it should update when first value is changed"
  o2.set 110
  assert.strictEqual result.value(), 83, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#greaterThan()', ->
  o1 = new RObject(8)
  o2 = new RObject(6)
  result = o1.greaterThan(o2)
  assert.strictEqual result.value(), true, "it should test the initial values"
  o1.set 3
  assert.strictEqual result.value(), false, "it should update when first value is changed"
  o2.set -5
  assert.strictEqual result.value(), true, "it should update when second value is changed"
  o1.set -5
  assert.strictEqual result.value(), false, "equal numbers should fail the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#greaterThanOrEqual()', ->
  o1 = new RObject(8)
  o2 = new RObject(6)
  result = o1.greaterThanOrEqual(o2)
  assert.strictEqual result.value(), true, "it should test the initial values"
  o1.set 3
  assert.strictEqual result.value(), false, "it should update when first value is changed"
  o2.set -5
  assert.strictEqual result.value(), true, "it should update when second value is changed"
  o1.set -5
  assert.strictEqual result.value(), true, "equal numbers should pass the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#lessThan()', ->
  o1 = new RObject(8)
  o2 = new RObject(6)
  result = o1.lessThan(o2)
  assert.strictEqual result.value(), false, "it should test the initial values"
  o1.set 3
  assert.strictEqual result.value(), true, "it should update when first value is changed"
  o2.set -5
  assert.strictEqual result.value(), false, "it should update when second value is changed"
  o1.set -5
  assert.strictEqual result.value(), false, "equal numbers should fail the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#lessThanOrEqual()', ->
  o1 = new RObject(8)
  o2 = new RObject(6)
  result = o1.lessThanOrEqual(o2)
  assert.strictEqual result.value(), false, "it should test the initial values"
  o1.set 3
  assert.strictEqual result.value(), true, "it should update when first value is changed"
  o2.set -5
  assert.strictEqual result.value(), false, "it should update when second value is changed"
  o1.set -5
  assert.strictEqual result.value(), true, "equal numbers should pass the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"



#todo: array concat
describe '#concat()', ->
  it 'should concat the initial values', ->
    o1 = new RObject('foo')
    o2 = new RObject('bar')
    assert.strictEqual o1.concat(o2).value(), 'foobar'

  it 'should return an RObject', ->
    o1 = new RObject('foo')
    o2 = new RObject('bar')
    assert.equal o1.concat(o2) instanceof RObject, true

  it 'should update concated value when either value changes', ->
    o1 = new RObject('foo')
    o2 = new RObject('')
    result = o1.concat(o2)
    o2.set 'bar'
    assert.strictEqual result.value(), 'foobar'
    o1.set 'baz'
    assert.strictEqual result.value(), 'bazbar'

describe '#indexOf()', ->
  it 'should have initial index value', ->
    o1 = new RObject('foobarbaz')
    o2 = new RObject('bar')
    assert.strictEqual o1.indexOf(o2).value(), 3

  it 'should return an RObject', ->
    o1 = new RObject('foobarbaz')
    o2 = new RObject('bar')
    assert.equal o1.indexOf(o2) instanceof RObject, true

  it 'should give -1 for not found', ->
    o1 = new RObject('foobarbaz')
    o2 = new RObject('zing')
    assert.strictEqual o1.indexOf(o2).value(), -1

  it 'should update index when either value changes', ->
    o1 = new RObject('barbaz')
    o2 = new RObject('bar')
    result = o1.indexOf(o2)
    o1.set 'foobarbaz'
    assert.strictEqual result.value(), 3
    o2.set 'arb'
    assert.strictEqual result.value(), 4

describe '#at()', ->
  it 'should give item at the specified index', ->
    one = new RObject(1)
    two = new RObject(2)
    three = new RObject(3)
    a = new RObject([one, two, three])
    assert.equal a.at(new RObject(0)).value(), one.value()
    assert.equal a.at(new RObject(1)).value(), two.value()
    assert.equal a.at(new RObject(2)).value(), three.value()

  it 'should update item at index when array is changed', ->
    one = new RObject(1)
    two = new RObject(2)
    three = new RObject(3)
    a = new RObject([one, three])
    atIndex1 = a.at(new RObject(1))
    a.splice 1, 0, two
    assert.equal atIndex1.value(), two.value()

  it 'should update item at index when index is changed', ->
    index = new RObject(1)
    a = new RObject([1, 2, 3])
    atIndex = a.at(index)
    assert.equal atIndex.value(), 2
    index.set 2
    assert.equal atIndex.value(), 3



describe '#prop()', ->
  describe 'type: Object', ->
    it 'should allow getting properties of passed in the constructor', ->
      o = new RObject { eight: '8', nine: new RObject('9') }
      assert.equal '8', o.prop('eight').value()
      assert.equal '9', o.prop('nine').value()

    it 'should allow setting properties and getting them back', ->
      o = new RObject {}
      o.prop 'great', 'job'
      assert.equal 'job', o.prop('great').value()

    it 'should give empty when accessing unset property', ->
      o = new RObject {}
      assert.strictEqual null, o.prop('lol').value()

    it 'should set property to empty when set to undefined', ->
      o = new RObject {}
      o.prop 'great', undefined
      assert.strictEqual null, o.prop('great').value()

  describe 'type: Other', ->
    it 'should give empty', ->
      everyType (o) ->
        prop = o.prop('a')
        o.set(null)
        assert.equal null, prop.toObject()


  it 'should handle dynamic type change', ->
    everyType (o) ->
      prop = o.prop 'as'
      o.set {as: 'df'}
      assert.equal 'df', prop.value()
      o.set 5
      assert.equal null, prop.value()


# descrive '#keys()', ->
#   it 'should give keys of initialize object', ->
#     o = new RObject({jabba: 'wockeez'})
#     assert.equal o.keys()