
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

describe '#set()', ->
  it 'should not fire change event when set to the same value', ->
    o = new RObject()
    o.on 'change', -> changes++
    for val in typeValues
      o.set val
      changes = 0
      o.set val
      assert.equal changes, 0

describe '#type()', ->
  it 'should detect the type based on what is passed in', ->
    assert.equal 'number', new RObject(8).type().value()
    assert.equal 'string', new RObject('8').type().value()
    assert.equal 'boolean', new RObject(true).type().value()
    assert.equal 'empty', new RObject(null).type().value()
    assert.equal 'empty', new RObject(undefined).type().value()
    assert.equal 'object', new RObject({}).type().value()
    assert.equal 'array', new RObject([]).type().value()

describe '#value()', ->
  it 'should return the same item rObject was created with', ->
    for item in [8, '8', true, null]
      assert.strictEqual item, new RObject(item).value()

  it 'should modify object passed in', ->
    original = {a: 'aee'}
    r = new RObject(original)
    r.prop 'a', 'lol'
    r.prop 'b', 'bbq'
    assert.equal original.a.value(), 'lol'
    assert.strictEqual original.b.value(), 'bbq'

  it 'should translate undefined to null', ->
    assert.strictEqual null, new RObject(null).value()
    assert.strictEqual null, new RObject(undefined).value()

  it 'should only convert to native object shallow', ->
    assert.equal true, new RObject({ five: new RObject(5) }).value().five instanceof RObject
    assert.equal 5, new RObject({ five: new RObject(5) }).value().five.value()
    assert.equal true, new RObject([ new RObject(5) ]).value()[0] instanceof RObject
    assert.equal 5, new RObject([ new RObject(5) ]).value()[0].value()

  it 'should give value of values added later', ->
    o = new RObject({})
    o.prop('cat', 'mouse')
    assert.equal 'mouse', o.value().cat.value()

    o = new RObject([])
    o.splice 0, 0, new RObject(4)
    assert.equal 4, o.value()[0].value()

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
      new RObject([new RObject(3)])
      new RObject({
        one: 1
        two: new RObject('2')
        more: new RObject({
          a: new RObject('aee')
          b: 'bee'
        })
      })
    ])
    assert.deepEqual complex.toObject(), ['foo', 6, true, [3], {one: '1', two: '2', more: {a: 'aee', b: 'bee'}}]

  it 'should give native value for items that have had a property accessed', ->
    o = new RObject({ d: false })
    o.prop 'd'
    assert.deepEqual { d: false }, o.toObject()

describe '#inverse()', ->
  describe 'type: boolean', ->
    it 'should inverse value', ->
      rs = new RObject(false)
      inverse = rs.inverse()
      assert.strictEqual inverse.value(), true
      rs.set true
      assert.strictEqual inverse.value(), false

  describe 'type: number', ->
    it 'should inverse', ->
      rs = new RObject(8)
      inverse = rs.inverse()
      assert.strictEqual inverse.value(), -8
      rs.set -8
      assert.strictEqual inverse.value(), 8

  describe 'type: other', ->
    it 'should noop', ->
      rs = new RObject('8')
      inverse = rs.inverse()
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

  ro = new RObject([])
  ro.splice 0, 0, nums[0], nums[1]
  assert.deepEqual ro.toObject(), [0, 1]

  it 'should add to beginning', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      assert.deepEqual items, nums[2]
      assert.strictEqual index, 0
      addCalls++
    remove = (items, {index}) ->
      removeCalls++

    ro.on 'add', add
    ro.on 'remove', remove

    ro.splice 0, 0, nums[2]
    assert.deepEqual ro.toObject(), [2, 0, 1]
    assert.equal addCalls, 1
    assert.equal removeCalls, 0

    ro.removeListener 'add', add
    ro.removeListener 'remove', remove

  it 'should add to end', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      assert.deepEqual items, nums[3]
      assert.strictEqual index, 3
      addCalls++
    remove = (items, {index}) ->
      removeCalls++

    ro.on 'add', add
    ro.on 'remove', remove

    ro.splice 3, 0, nums[3]
    assert.deepEqual ro.toObject(), [2, 0, 1, 3]
    assert.equal addCalls, 1
    assert.equal removeCalls, 0

    ro.removeListener 'add', add
    ro.removeListener 'remove', remove

  it 'should remove 1 at index', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      addCalls++
    remove = (items, {index}) ->
      assert.deepEqual items, nums[0]
      assert.strictEqual index, 1
      removeCalls++

    ro.on 'add', add
    ro.on 'remove', remove

    removed = ro.splice 1, 1
    assert.deepEqual ro.toObject(), [2, 1, 3]
    # assert.deepEqual removed, []
    assert.equal addCalls, 0
    assert.equal removeCalls, 1

    ro.removeListener 'add', add
    ro.removeListener 'remove', remove

  it 'should remove and add at the index', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      assert.deepEqual items, [nums[4], nums[5], nums[6], nums[7]]
      assert.strictEqual index, 1
      assert.equal removeCalls, 1, 'remove event should be fired before add event'
      addCalls++
    remove = (items, {index}) ->
      assert.deepEqual items, nums[1]
      assert.strictEqual index, 1
      removeCalls++

    ro.on 'add', add
    ro.on 'remove', remove

    ro.splice 1, 1, nums[4], nums[5], nums[6], nums[7]
    assert.deepEqual ro.toObject(), [2, 4, 5, 6, 7, 3]
    assert.equal addCalls, 1
    assert.equal removeCalls, 1

    ro.removeListener 'add', add
    ro.removeListener 'remove', remove

  it 'should remove all', ->
    addCalls = 0
    removeCalls = 0
    add = (items, {index}) ->
      addCalls++
    remove = (items, {index}) ->
      assert.deepEqual items, [nums[2], nums[4], nums[5], nums[6], nums[7], nums[3]]
      assert.strictEqual index, 0
      removeCalls++

    ro.on 'add', add
    ro.on 'remove', remove

    ro.splice 0, 6
    assert.deepEqual ro.toObject(), []
    assert.equal addCalls, 0
    assert.equal removeCalls, 1

    ro.removeListener 'add', add
    ro.removeListener 'remove', remove

  #todo: change events
  #todo: negative number indexes
  #todo: edge cases




describe '#map()', ->
  describe 'type: Array', ->
    it 'should map initial items', ->
      ro = new RObject([new RObject(1), new RObject(2)])
      inversed = ro.map (item) ->
        item.inverse()
      assert.deepEqual inversed.value().map((i) -> i.value()), [-1, -2]

    it 'should map items added later', ->
      ro = new RObject([new RObject(1)])
      inversed = ro.map (item) ->
        item.inverse()
      ro.add new RObject(2)
      assert.deepEqual inversed.toObject(), [-1, -2]

    it 'should remove items from the child when items are removed from the parent', ->
      ro = new RObject([new RObject(1), new RObject(2), new RObject(3)])
      inversed = ro.map (item) ->
        item.inverse()
      ro.splice 1, 1

      assert.deepEqual inversed.toObject(), [-1, -3]

    it 'should only call transform fn once when item is added', ->
      ro = new RObject([new RObject(1)])
      transforms = 0
      inversed = ro.map (item) ->
        transforms++
        item.inverse()

      transforms = 0
      ro.add new RObject(2)
      assert.equal transforms, 1

    it 'should update when parent value changes and not rerun transform fn', ->
      cbs = 0
      num = new RObject(1)
      ro = new RObject([num])
      inversed = ro.map (item) ->
        cbs++
        item.inverse()

      num.set(2)
      assert.deepEqual inversed.toObject(), [-2]
      assert.equal cbs, 1

  describe 'type: Other', ->
    it 'should return null', ->
      o = new RObject()
      inversed = o.map (item) ->
        item.inverse()

      assert.deepEqual inversed.value(), null

  it 'should handle dynamic type change', ->
    ro = new RObject()
    inversed = ro.map (item) ->
      item.inverse()

    ro.set [new RObject(3)]
    assert.deepEqual inversed.toObject(), [-3]
    ro.set null
    assert.deepEqual inversed.value(), null



describe '#filter()', ->
  isEven = (num) ->
    num.mod(new RObject(2)).is(new RObject(0))

  describe 'type: Array', ->
    it 'should filter initial items', ->
      ro = new RObject([new RObject(4), new RObject(5), new RObject(6)])
      evens = ro.filter isEven
      assert.deepEqual evens.toObject(), [4, 6]

    it 'should filter added items', ->
      ro = new RObject([new RObject(4), new RObject(5), new RObject(6)])
      evens = ro.filter isEven
      ro.add new RObject(7)
      assert.deepEqual evens.toObject(), [4, 6]
      ro.add new RObject(8)
      assert.deepEqual evens.toObject(), [4, 6, 8]

    it 'should filter added items when more than one is added at a time', ->
      ro = new RObject([new RObject(4), new RObject(5), new RObject(6)])
      evens = ro.filter isEven
      ro.add [new RObject(7), new RObject(8)]
      assert.deepEqual evens.toObject(), [4, 6, 8]

    it 'should filter added items and put them in the correct place when spliced', ->
      ro = new RObject([new RObject(1), new RObject(2), new RObject(4), new RObject(3), new RObject(3), new RObject(5), new RObject(9), new RObject(12)])
      evens = ro.filter isEven
      ro.splice 5, 0, new RObject(7), new RObject(8), new RObject(9), new RObject(10)
      assert.deepEqual evens.toObject(), [2, 4, 8, 10, 12]

    it 'should filter added items and put them in the correct place when spliced at position 0', ->
      ro = new RObject([new RObject(3), new RObject(4)])
      evens = ro.filter isEven
      ro.splice 0, 0, new RObject(2)
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
      ro = new RObject([3])
      isRObject = false
      evens = ro.filter (val) ->
        isRObject = val instanceof RObject
        new RObject(true)

      assert.equal isRObject, true

    it 'should update filter when given boolean changes', ->
      first = new RObject(3)
      ro = new RObject([first])
      evens = ro.filter isEven
      first.set 4
      assert.deepEqual evens.toObject(), [4]
      first.set 3
      assert.deepEqual evens.toObject(), []

    it 'should update filter when given boolean changes for dynamically added items', ->
      four = new RObject(4)
      ro = new RObject([new RObject(2), new RObject(3), new RObject(5), new RObject(6)])
      evens = ro.filter isEven
      ro.splice 2, 0, four
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
      o.value()[3].set 3
      assert.deepEqual evens.toObject(), [2, 6]


  it 'should handle dynamic type change', ->
    o = new RObject()
    evens = o.filter isEven
    o.set [new RObject(3), new RObject(4)]
    assert.deepEqual evens.toObject(), [4]
    o.set null
    assert.deepEqual evens.toObject(), null


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


describe '#add()', ->
  it 'should add item and trigger add event', ->
    ro = new RObject([])
    one = new RObject(1)
    addTriggered = false
    ro.on 'add', (item, {index}) ->
      assert.strictEqual item, one, 'add event should include added item'
      assert.strictEqual ro.length().value(), 1, 'array length should be updated by the time add event is triggered'
      assert.strictEqual index, 0, 'add event should include index'
      addTriggered = true

    ro.add one
    assert.equal addTriggered, true
    assert.deepEqual ro.value(), [one]

  it 'should add at the index if one is specified', ->
    ro = new RObject([new RObject(5), new RObject(6), new RObject(7)])
    one = new RObject(1)
    addTriggered = false
    ro.on 'add', (item, {index}) ->
      assert.strictEqual item, one, 'add event should include added item'
      assert.strictEqual ro.length().value(), 4, 'array length should be updated by the time add event is triggered'
      assert.strictEqual index, 2, 'add event should include index'
      addTriggered = true

    ro.add one, {at: 2}
    assert.equal addTriggered, true
    assert.deepEqual ro.toObject(), [5, 6, 1, 7]

  it 'should allow adding multiple items via Array', ->
    ro = new RObject([new RObject(3), new RObject(8), new RObject(9)])
    addsTriggered = 0
    four = new RObject(4)
    five = new RObject(5)
    six = new RObject(6)
    seven = new RObject(7)
    ro.on 'add', (item, {index}) ->
      assert.deepEqual item, [four, five, six, seven], 'add event should include added items'
      assert.strictEqual ro.length().value(), 7, 'array length should be updated by the time add event is triggered'
      assert.strictEqual index, 1, 'add event should include index'
      addsTriggered++

    ro.add [four, five, six, seven], {at: 1}
    assert.deepEqual ro.toObject(), [3, 4, 5, 6, 7, 8, 9]
    assert.equal addsTriggered, 1

describe '#add()', ->
  rn1 = new RObject(5)
  rn2 = new RObject(6)
  result = rn1.add(rn2)
  assert.strictEqual result.value(), 11
  rn1.set 12
  assert.strictEqual result.value(), 18, "it should update when first value is changed"
  rn2.set 33
  assert.strictEqual result.value(), 45, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#subtract()', ->
  rn1 = new RObject(5)
  rn2 = new RObject(6)
  result = rn1.subtract(rn2)
  assert.strictEqual result.value(), -1, "it should subtract the initial values"
  rn1.set 12
  assert.strictEqual result.value(), 6, "it should update when first value is changed"
  rn2.set 33
  assert.strictEqual result.value(), -21, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#multiply()', ->
  rn1 = new RObject(5)
  rn2 = new RObject(6)
  result = rn1.multiply(rn2)
  assert.strictEqual result.value(), 30, "it should multiply the initial values"
  rn1.set 12
  assert.strictEqual result.value(), 72, "it should update when first value is changed"
  rn2.set 33
  assert.strictEqual result.value(), 396, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#divide()', ->
  rn1 = new RObject(-12)
  rn2 = new RObject(6)
  result = rn1.divide(rn2)
  assert.strictEqual result.value(), -2, "it should divide the initial values"
  rn1.set 36
  assert.strictEqual result.value(), 6, "it should update when first value is changed"
  rn2.set 3
  assert.strictEqual result.value(), 12, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"

  it 'should be Infinity when dividing by 0', ->
    result = new RObject(12).divide(new RObject(0))
    assert.equal result.value(), Infinity


describe '#mod()', ->
  rn1 = new RObject(1046)
  rn2 = new RObject(100)
  result = rn1.mod(rn2)
  assert.strictEqual result.value(), 46, "it should mod the initial values"
  rn1.set 1073
  assert.strictEqual result.value(), 73, "it should update when first value is changed"
  rn2.set 110
  assert.strictEqual result.value(), 83, "it should update when second value is changed"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#greaterThan()', ->
  rn1 = new RObject(8)
  rn2 = new RObject(6)
  result = rn1.greaterThan(rn2)
  assert.strictEqual result.value(), true, "it should test the initial values"
  rn1.set 3
  assert.strictEqual result.value(), false, "it should update when first value is changed"
  rn2.set -5
  assert.strictEqual result.value(), true, "it should update when second value is changed"
  rn1.set -5
  assert.strictEqual result.value(), false, "equal numbers should fail the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#greaterThanOrEqual()', ->
  rn1 = new RObject(8)
  rn2 = new RObject(6)
  result = rn1.greaterThanOrEqual(rn2)
  assert.strictEqual result.value(), true, "it should test the initial values"
  rn1.set 3
  assert.strictEqual result.value(), false, "it should update when first value is changed"
  rn2.set -5
  assert.strictEqual result.value(), true, "it should update when second value is changed"
  rn1.set -5
  assert.strictEqual result.value(), true, "equal numbers should pass the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#lessThan()', ->
  rn1 = new RObject(8)
  rn2 = new RObject(6)
  result = rn1.lessThan(rn2)
  assert.strictEqual result.value(), false, "it should test the initial values"
  rn1.set 3
  assert.strictEqual result.value(), true, "it should update when first value is changed"
  rn2.set -5
  assert.strictEqual result.value(), false, "it should update when second value is changed"
  rn1.set -5
  assert.strictEqual result.value(), false, "equal numbers should fail the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"


describe '#lessThanOrEqual()', ->
  rn1 = new RObject(8)
  rn2 = new RObject(6)
  result = rn1.lessThanOrEqual(rn2)
  assert.strictEqual result.value(), false, "it should test the initial values"
  rn1.set 3
  assert.strictEqual result.value(), true, "it should update when first value is changed"
  rn2.set -5
  assert.strictEqual result.value(), false, "it should update when second value is changed"
  rn1.set -5
  assert.strictEqual result.value(), true, "equal numbers should pass the test"
  assert.equal result instanceof RObject, true, "it should return an RObject"



#todo: array concat
describe '#concat()', ->
  it 'should concat the initial values', ->
    rs1 = new RObject('foo')
    rs2 = new RObject('bar')
    assert.strictEqual rs1.concat(rs2).value(), 'foobar'

  it 'should return an RObject', ->
    rs1 = new RObject('foo')
    rs2 = new RObject('bar')
    assert.equal rs1.concat(rs2) instanceof RObject, true

  it 'should update concated value when either value changes', ->
    rs1 = new RObject('foo')
    rs2 = new RObject('')
    result = rs1.concat(rs2)
    rs2.set 'bar'
    assert.strictEqual result.value(), 'foobar'
    rs1.set 'baz'
    assert.strictEqual result.value(), 'bazbar'

describe '#indexOf()', ->
  it 'should have initial index value', ->
    rs1 = new RObject('foobarbaz')
    rs2 = new RObject('bar')
    assert.strictEqual rs1.indexOf(rs2).value(), 3

  it 'should return an RObject', ->
    rs1 = new RObject('foobarbaz')
    rs2 = new RObject('bar')
    assert.equal rs1.indexOf(rs2) instanceof RObject, true

  it 'should give -1 for not found', ->
    rs1 = new RObject('foobarbaz')
    rs2 = new RObject('zing')
    assert.strictEqual rs1.indexOf(rs2).value(), -1

  it 'should update index when either value changes', ->
    rs1 = new RObject('barbaz')
    rs2 = new RObject('bar')
    result = rs1.indexOf(rs2)
    rs1.set 'foobarbaz'
    assert.strictEqual result.value(), 3
    rs2.set 'arb'
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
    a = new RObject([new RObject(1), new RObject(2), new RObject(3)])
    atIndex = a.at(index)
    assert.equal atIndex.value(), 2
    index.set 2
    assert.equal atIndex.value(), 3



describe '#prop()', ->
  describe 'type: Object', ->
    it 'should allow getting properties of passed in the constructor', ->
      ro = new RObject { eight: '8', nine: new RObject('9') }
      assert.equal '8', ro.prop('eight').value()
      assert.equal '9', ro.prop('nine').value()

    it 'should allow setting properties and getting them back', ->
      ro = new RObject {}
      ro.prop 'great', 'job'
      assert.equal 'job', ro.prop('great').value()

    it 'should give empty when accessing unset property', ->
      ro = new RObject {}
      assert.strictEqual null, ro.prop('lol').value()

    it 'should set property to empty when set to undefined', ->
      ro = new RObject {}
      ro.prop 'great', undefined
      assert.strictEqual null, ro.prop('great').value()

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