
assert = require 'assert'
_clone = require 'lodash.clone'

RObject = require '../src/RObject'

# never ever ever use assert.equal, 8 == ['8'] // true

#todo: test empty cases and stuff

# everything that returns an RObject should handle type changes of self

# #watch()

#todo: test accessing array items via prop
#todo: add test for cyclical object
#todo: add test for cyclical array
#todo: test for own of value

#todo: test event methods

#todo: make sure all methods are chainable

#todo #length()

#todo: #combine() or _ it

#todo: all ref* methods

#todo: original object shouldnt be modified other than being syncd to

#todo:  make sure all methods work with multi-adds/removes

#todo: type change event is fired before value changes

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

clone = (o) ->
  if o
    return JSON.parse(JSON.stringify(o))

  return o

# to test every edge case it's a good idea to make sure things
#  work no matter what the previous state of the RObject was
# run the fn for every possible type and set type
everyType = (fn) ->
  # straight instantiated with the value
  for typeValue, i in typeValues
    fn new RObject(clone(typeValue)), types[i], typeValue

  # set to value later
  for typeValue in typeValues
    for setValue, i in typeValues
      fn new RObject(clone(typeValue)).set(clone(setValue)), types[i], setValue

everyTypeExcept = (blacklist, fn) ->
  everyType (result, type, value) =>
    if type != blacklist
      fn result, type, value

describe 'constructor', ->
  it 'should allow creation with an object that has RObject properties', ->
    new RObject({ a: new RObject('aaa') })

  # these might just be testing for an optimization, I'm not really sure
  it 'should only be 1 proxy level deep when passed in RObject property is accessed with prop', ->
    prop = new RObject('aaa')
    o = new RObject({ a: prop })
    assert.strictEqual o.prop('a').refValue(), prop

  # it 'should only be 1 proxy level deep when passed in RObject array item is accessed with at', ->
  #   item = new RObject('aaa')
  #   o = new RObject([item])
  #   assert.strictEqual o.at(0).refValue(), item


describe '#set()', ->

  it 'should change the value to the set value', ->
    o = new RObject()
    o.set 6
    assert.strictEqual o.value(), 6

  it 'should change the value of the proxy to the set value on proxy', ->
    original = new RObject()
    proxy = new RObject(original)
    proxy.set 6
    assert.strictEqual proxy.value(), 6

  it 'should change the value of the original to the set value on proxy', ->
    original = new RObject()
    proxy = new RObject(original)
    proxy.set 6
    assert.strictEqual original.value(), 6

  it 'should change the value of the proxy to the set value on original', ->
    original = new RObject()
    proxy = new RObject(original)
    original.set 6
    assert.strictEqual proxy.value(), 6

  it 'should change value when set to a value that would be == to the thing being set', ->
    o = new RObject(8)
    o.set '8'
    assert.strictEqual o.value(), '8'

  it 'should update length when value changes to an array', ->
    o = new RObject()
    o.set [1, 2, 3, 4, 5]
    assert.strictEqual o.length().value(), 5

  it 'should update length when value changes to a string', ->
    o = new RObject()
    o.set 'barbaque'
    assert.strictEqual o.length().value(), 8

  describe 'change event', ->
    it 'should not fire when set to the same empty value', ->
      o = new RObject()
      changes = 0
      o.on 'change', -> changes++
      o.set null
      assert.strictEqual changes, 0

    it 'should not fire when set to the same boolean value', ->
      o = new RObject(false)
      changes = 0
      o.on 'change', -> changes++
      o.set false
      assert.strictEqual changes, 0

    it 'should not fire when set to the same number value', ->
      o = new RObject(7)
      changes = 0
      o.on 'change', -> changes++
      o.set 7
      assert.strictEqual changes, 0

    it 'should not fire when set to the same string value', ->
      o = new RObject('bbq')
      changes = 0
      o.on 'change', -> changes++
      o.set 'bbq'
      assert.strictEqual changes, 0

    it 'should not fire when set to the same object value', ->
      val = { a: 'aaa' }
      o = new RObject(val)
      changes = 0
      o.on 'change', -> changes++
      o.set val
      assert.strictEqual changes, 0

    it 'should not fire when set to the same array value', ->
      val = [1, 2, 3]
      o = new RObject(val)
      changes = 0
      o.on 'change', -> changes++
      o.set val
      assert.strictEqual changes, 0

    #todo: should not fire add/remove either

    it 'should not fire on original when proxy is set to the same value', ->
      original = new RObject('bbq')
      proxy = new RObject(original)
      changes = 0
      original.on 'change', -> changes++
      proxy.set 'bbq'
      assert.strictEqual changes, 0

    it 'should not fire on proxy when proxy is set to the same value', ->
      original = new RObject('bbq')
      proxy = new RObject(original)
      changes = 0
      proxy.on 'change', -> changes++
      proxy.set 'bbq'
      assert.strictEqual changes, 0

    it 'should not fire on proxy when original is set to the same value', ->
      original = new RObject('bbq')
      proxy = new RObject(original)
      changes = 0
      proxy.on 'change', -> changes++
      original.set 'bbq'
      assert.strictEqual changes, 0


    it 'should fire 1 time when value changes to empty', ->
      o = new RObject(123)
      changes = 0
      o.on 'change', -> changes++
      o.set null
      assert.strictEqual changes, 1

    it 'should fire 1 time when value changes to a boolean', ->
      o = new RObject()
      changes = 0
      o.on 'change', -> changes++
      o.set false
      assert.strictEqual changes, 1

    it 'should fire 1 time when value changes to a number', ->
      o = new RObject()
      changes = 0
      o.on 'change', -> changes++
      o.set 8
      assert.strictEqual changes, 1

    it 'should fire 1 time when value changes to a string', ->
      o = new RObject()
      changes = 0
      o.on 'change', -> changes++
      o.set 'asdf'
      assert.strictEqual changes, 1

    it 'should fire 1 time when value changes to a object', ->
      o = new RObject()
      changes = 0
      o.on 'change', -> changes++
      o.set {}
      assert.strictEqual changes, 1

    it 'should fire 1 time when value changes to a array', ->
      o = new RObject()
      changes = 0
      o.on 'change', -> changes++
      o.set []
      assert.strictEqual changes, 1

    it 'should fire on original 1 time when proxy value changes', ->
      original = new RObject()
      proxy = new RObject(original)
      changes = 0
      original.on 'change', -> changes++
      proxy.set 'asdf'
      assert.strictEqual changes, 1

    it 'should fire on proxy 1 time when proxy value changes', ->
      original = new RObject()
      proxy = new RObject(original)
      changes = 0
      proxy.on 'change', -> changes++
      proxy.set 'asdf'
      assert.strictEqual changes, 1

    it 'should fire on proxy 1 time when original value changes', ->
      original = new RObject()
      proxy = new RObject(original)
      changes = 0
      proxy.on 'change', -> changes++
      original.set 'asdf'
      assert.strictEqual changes, 1


    it 'should update length before change event when value changes to an array', ->
      o = new RObject()
      changeLength = null
      o.on 'change', ->
        changeLength = o.length().value()
      o.set [1, 2, 3, 4, 5]
      assert.strictEqual changeLength, 5

    it 'should update length before change event when value changes to a string', ->
      o = new RObject()
      changeLength = null
      o.on 'change', ->
        changeLength = o.length().value()
      o.set 'barbaque'
      assert.strictEqual changeLength, 8


describe '#refSet', ->

  it 'should change the value to the set value for non-RObject values', ->
    o = new RObject()
    o.refSet 6
    assert.strictEqual o.value(), 6

  it 'should change the value of the root value to the refSet RObject value', ->
    neu = new RObject 23
    old = new RObject 8
    root = new RObject old
    root.refSet neu
    assert.strictEqual root.value(), 23

  it 'shouldnt touch the previous RObjects value', ->
    neu = new RObject 23
    old = new RObject 8
    root = new RObject old
    root.refSet neu
    assert.strictEqual old.value(), 8

  it 'should change value when set to a value that would be == to the thing being set', ->
    o = new RObject(8)
    o.refSet '8'
    assert.strictEqual o.value(), '8'

  it 'should update length when value changes to an array', ->
    o = new RObject()
    o.refSet [1, 2, 3, 4, 5]
    assert.strictEqual o.length().value(), 5

  it 'should update length when value changes to a string', ->
    o = new RObject()
    o.refSet 'barbaque'
    assert.strictEqual o.length().value(), 8

  describe 'change event', ->

    it 'should fire 1 time on proxy when proxy is set to the same value', ->
      original = new RObject('bbq')
      proxy = new RObject(original)
      changes = 0
      proxy.on 'change', -> changes++
      proxy.refSet 'bbq'
      assert.strictEqual changes, 1

    it 'should fire on proxy 1 time when proxy value changes', ->
      original = new RObject()
      proxy = new RObject(original)
      changes = 0
      proxy.on 'change', -> changes++
      proxy.refSet 'asdf'
      assert.strictEqual changes, 1

    it 'should stop calling change event when RObject is set to another value', ->
      old = new RObject(5)
      neu = new RObject(8)
      root = new RObject(old)
      root.refSet neu
      changes = 0
      root.on 'change', ->
        changes++
      old.set 2
      assert.strictEqual changes, 0




    it 'should not change "add event fire value" when base element value changes', ->
      o = new RObject([1])
      added = null
      o.on 'add', (val) -> added = val
      o.add [2, 3]
      o.set [4, 5, 6]
      assert.deepEqual added.map((o) -> o.value()), [2, 3]









describe '#value()', ->
  it 'should give the value when RObject was created with a number', ->
    assert.strictEqual new RObject(8).value(), 8

  it 'should give the value when RObject was created with a string', ->
    assert.strictEqual new RObject('bbq').value(), 'bbq'

  it 'should give the value when RObject was created with a boolean', ->
    assert.strictEqual new RObject(false).value(), false

  it 'should give the value when RObject was created with a null', ->
    assert.strictEqual new RObject(null).value(), null

  it 'should give the value null when RObject was created with an implicit undefined', ->
    assert.strictEqual new RObject().value(), null

  it 'should give the value null when RObject was created with an explicit undefined', ->
    assert.strictEqual new RObject(undefined).value(), null

  it 'should give exact same value when RObject was created with an object', ->
    plain = {a: 'aaa'}
    assert.strictEqual new RObject(plain).value(), plain

  it 'should give exact same value when RObject was created with an array', ->
    arr = [1, 2, 3]
    assert.strictEqual new RObject(arr).value(), arr

  it 'should give the value of the real object', ->
    original = new RObject(6)
    proxy = new RObject(original)
    assert.strictEqual proxy.value(), 6

  describe 'Objects', ->
    it 'should give values of new object when value is set to a new object', ->
      o = new RObject({ a: 'aaa' })
      o.set { b: 'bbb' }
      assert.strictEqual o.value().b, 'bbb'

    it 'should not give values of old object when value is set to a new object', ->
      o = new RObject({ a: 'aaa' })
      o.set { b: 'bbb' }
      assert.strictEqual o.value().a, undefined

    it 'should give value of values added later via prop', ->
      o = new RObject({})
      o.prop 'cat', 'mouse'
      assert.strictEqual o.value().cat, 'mouse'

    #todo: dont assign the RObject to _val, just assign the value, it will be updated when sync is called
    it 'should modify object passed in for changed values', ->
      original = {a: 'aee'}
      o = new RObject(original)
      o.prop 'a', 'lol'
      assert.strictEqual original.a.value(), 'lol'

    it 'should modify object passed in for new values added via prop', ->
      original = {}
      o = new RObject(original)
      o.prop 'b', 'bbq'
      assert.strictEqual original.b.value(), 'bbq'

    it 'should modify object passed in for new values added by set on prop', ->
      original = {}
      o = new RObject(original)
      b = o.prop 'b'
      b.set 'bbq'
      assert.strictEqual original.b.value(), 'bbq'

    it 'should give native value for items that have had a property accessed', ->
      o = new RObject({ d: false })
      o.prop 'd'
      assert.deepEqual o.value(), { d: false }

    it 'should recursively convert to native value', ->
      assert.deepEqual new RObject({ bbq: { a: 'aaa' } }).value(), { bbq: { a: 'aaa' } }

    it 'should give value of given RObject when created with an RObject', ->
      o = new RObject([new RObject(8)])
      assert.deepEqual o.value(), [8]

  describe 'Arrays', ->
    it 'should give values of new array when value is set to a new array', ->
      o = new RObject([])
      o.set ['one']
      assert.strictEqual o.value()[0], 'one'

    it 'should not give values of old object when value is set to a new object', ->
      o = new RObject(['aaa'])
      o.set []
      assert.strictEqual o.value()[0], undefined

    it 'should give value of values added later via at', ->
      o = new RObject([])
      o.at(0).set 111
      assert.strictEqual o.value()[0], 111

    it 'should modify object passed in for changed values', ->
      original = ['aaa']
      o = new RObject(original)
      zero = o.at(0)
      zero.set 'bbb'
      assert.strictEqual original[0].value(), 'bbb'

    it 'should modify object passed in for new values', ->
      original = []
      o = new RObject(original)
      o.at(0).set 'lol'
      assert.strictEqual original[0].value(), 'lol'

    it 'should give native value for items that have had an item accessed', ->
      o = new RObject(['aaa'])
      o.at(0)
      assert.deepEqual o.value(), ['aaa']

    it 'should recursively convert to native value', ->
      assert.deepEqual new RObject([['bbq']]).value(), [['bbq']]



describe '#type()', ->
  it 'should give the correct type for numbers', ->
    assert.strictEqual new RObject(8).type().value(), 'number'

  it 'should give the correct type for strings', ->
    assert.strictEqual new RObject('8').type().value(), 'string'

  it 'should give the correct type for booleans', ->
    assert.strictEqual new RObject(true).type().value(), 'boolean'

  it 'should give the correct type (empty) for null', ->
    assert.strictEqual new RObject(null).type().value(), 'empty'

  it 'should give the correct type (empty) for undefined', ->
    assert.strictEqual new RObject(undefined).type().value(), 'empty'

  it 'should give the correct type for objects', ->
    assert.strictEqual new RObject({}).type().value(), 'object'

  it 'should give the correct type for arrays', ->
    assert.strictEqual new RObject([]).type().value(), 'array'

  it 'should fire change event 1 time when source value changes', ->
    o = new RObject(8)
    changes = 0
    o.type().on 'change', -> changes++
    o.set 'bbq'
    assert.strictEqual changes, 1

  it 'should update type value before firing change event', ->
    o = new RObject(8)
    type = o.type()
    changeValue = null
    type.on 'change', ->
      changeValue = type.value()
    o.set 'bbq'
    assert.strictEqual changeValue, 'string'

  it 'should dereference proxies', ->
    assert.strictEqual new RObject(new RObject('asdf')).type().value(), 'string'

  it 'should dynamically update proxy type value when proxy value changes', ->
    original = new RObject 8
    proxy = new RObject original
    proxyType = proxy.type()
    proxy.set 'bbq'
    assert.strictEqual proxyType.value(), 'string'

  it 'should dynamically update proxy type value when original value changes', ->
    original = new RObject 8
    proxy = new RObject original
    proxyType = proxy.type()
    original.set 'bbq'
    assert.strictEqual proxyType.value(), 'string'

  it 'should dynamically update original type value when proxy value changes', ->
    original = new RObject 8
    proxy = new RObject original
    originalType = original.type()
    proxy.set 'bbq'
    assert.strictEqual originalType.value(), 'string'

  it 'should fire change event 1 time on proxy type when proxy value changes', ->
    original = new RObject 8
    proxy = new RObject original
    changes = 0
    proxy.type().on 'change', -> changes++
    proxy.set 'bbq'
    assert.strictEqual changes, 1

  it 'should fire change event 1 time on original type when proxy value changes', ->
    original = new RObject 8
    proxy = new RObject original
    changes = 0
    original.type().on 'change', -> changes++
    proxy.set 'bbq'
    assert.strictEqual changes, 1

  it 'should fire change event 1 time on proxy type when original value changes', ->
    original = new RObject 8
    proxy = new RObject original
    changes = 0
    proxy.type().on 'change', -> changes++
    original.set 'bbq'
    assert.strictEqual changes, 1

  #todo: test order original/proxy change events are fired

  it 'should update proxy type value before firing change event', ->
    original = new RObject 8
    proxy = new RObject original
    type = proxy.type()
    changeValue = null
    type.on 'change', ->
      changeValue = type.value()
    proxy.set 'bbq'
    assert.strictEqual changeValue, 'string'


  it 'should update type of original when it is dynamically set to a proxy', ->
    original = new RObject('cow')
    proxy = new RObject(6)
    type = original.type()
    original.set proxy
    assert.strictEqual type.value(), 'number'

  it 'should fire 1 change event when original type changes from proxy', ->
    original = new RObject('cow')
    proxy = new RObject(6)
    type = original.type()
    changes = 0
    type.on 'change', -> changes++
    original.set proxy
    assert.strictEqual changes, 1

  it 'should update the value before firing change event when original type changes from proxy', ->
    original = new RObject('cow')
    proxy = new RObject(6)
    type = original.type()
    changeValue = null
    type.on 'change', -> changeValue = type.value()
    original.set proxy
    assert.strictEqual changeValue, 'number'

  it 'should update type of original when it is dynamically set from a proxy', ->
    original = new RObject('cow')
    proxy = new RObject(original)
    type = original.type()
    original.refSet 6
    assert.strictEqual type.value(), 'number'

  it 'should fire 1 change event when original type changes from proxy', ->
    original = new RObject('cow')
    proxy = new RObject(original)
    type = original.type()
    changes = 0
    type.on 'change', -> changes++
    original.refSet 6
    assert.strictEqual changes, 1

  it 'should update the value before firing change event when original type changes from proxy', ->
    original = new RObject('cow')
    proxy = new RObject(original)
    type = original.type()
    changeValue = null
    type.on 'change', -> changeValue = type.value()
    original.refSet 6
    assert.strictEqual changeValue, 'number'


# this inherits everything from #type(), should we retest it all?
describe '#refType()', ->
  it 'should give type proxy for RObject', ->
    assert.strictEqual new RObject(new RObject(6)).refType().value(), 'proxy'

  it 'should give type proxy when value is changed to RObject', ->
    o = new RObject(5)
    refType = o.refType()
    o.set new RObject(3)
    assert.strictEqual refType.value(), 'proxy'

  it 'should fire 1 change event when value is changed to RObject', ->
    o = new RObject(5)
    refType = o.refType()
    changes = 0
    refType.on 'change', -> changes++
    o.set new RObject(3)
    assert.strictEqual changes, 1

  it 'should change type value before firing change event when value is changed to RObject', ->
    o = new RObject(5)
    refType = o.refType()
    changeValue = 0
    refType.on 'change', -> changeValue = refType.value()
    o.set new RObject(3)
    assert.strictEqual changeValue, 'proxy'

  it 'should give type proxy when value is changed from RObject', ->
    o = new RObject(new RObject())
    refType = o.refType()
    o.refSet 6
    assert.strictEqual refType.value(), 'number'

  it 'should fire 1 change event when value is changed from RObject', ->
    o = new RObject(new RObject())
    refType = o.refType()
    changes = 0
    refType.on 'change', -> changes++
    o.refSet 6
    assert.strictEqual changes, 1

  it 'should change type value before firing change event when value is changed to RObject', ->
    o = new RObject(new RObject())
    refType = o.refType()
    changeValue = 0
    refType.on 'change', -> changeValue = refType.value()
    o.refSet 6
    assert.strictEqual changeValue, 'number'


describe '#inverse()', ->
  describe 'empty', ->
    it 'should give empty for initial empty', ->
      o = new RObject()
      inverse = o.inverse()
      assert.strictEqual inverse.value(), null

    it 'should clear dynamically changing value to empty', ->
      o = new RObject(true)
      inverse = o.inverse()
      o.set null
      assert.strictEqual inverse.value(), null

  #todo: should give null or self?
  describe 'string', ->
    it 'should give same value for initial string', ->
      o = new RObject('asdf')
      inverse = o.inverse()
      assert.strictEqual inverse.value(), 'asdf'

    it 'should give same value dynamically changing value to string', ->
      o = new RObject(true)
      inverse = o.inverse()
      o.set 'asdf'
      assert.strictEqual inverse.value(), 'asdf'

  describe 'object', ->
    it 'should give same value for initial object', ->
      o = new RObject({a: 'aaa'})
      inverse = o.inverse()
      assert.strictEqual inverse.value().a, 'aaa'

    it 'should give same value dynamically changing value to object', ->
      o = new RObject(true)
      inverse = o.inverse()
      o.set {a: 'aaa'}
      assert.strictEqual inverse.value().a, 'aaa'

  describe 'array', ->
    it 'should give same value for initial array', ->
      o = new RObject([3])
      inverse = o.inverse()
      assert.strictEqual inverse.value()[0], 3

    it 'should give same value dynamically changing value to array', ->
      o = new RObject(true)
      inverse = o.inverse()
      o.set [3]
      assert.strictEqual inverse.value()[0], 3

  describe 'boolean', ->
    it 'should inverse initial value', ->
      o = new RObject(false)
      inverse = o.inverse()
      assert.strictEqual inverse.value(), true

    it 'should inverse dynamically changing boolean', ->
      o = new RObject(false)
      inverse = o.inverse()
      o.set true
      assert.strictEqual inverse.value(), false

    it 'should inverse dynamically changing boolean from other type', ->
      o = new RObject()
      inverse = o.inverse()
      o.set true
      assert.strictEqual inverse.value(), false

  describe 'number', ->
    it 'should inverse initial value', ->
      o = new RObject(5)
      inverse = o.inverse()
      assert.strictEqual inverse.value(), -5

    it 'should inverse dynamically changing number', ->
      o = new RObject(6)
      inverse = o.inverse()
      o.set 7
      assert.strictEqual inverse.value(), -7

    it 'should inverse dynamically changing number from other type', ->
      o = new RObject()
      inverse = o.inverse()
      o.set 3
      assert.strictEqual inverse.value(), -3

  describe 'proxy', ->
    it.only 'should inverse a proxied number', ->
      original = new RObject(7)
      proxy = new RObject(original)
      inverse = proxy.inverse()
      assert.strictEqual inverse.value(), -7






#todo: edge case, called with empty and stuff
#todo: negative number indexes

describe '#splice()', ->

  it 'should do nothing when called with no items to add and none to remote', ->
    o = new RObject([])
    o.splice 0, 0
    assert.deepEqual o.value(), []

  it 'should splice in new items', ->
    o = new RObject([])
    o.splice 0, 0, 0, 1
    assert.deepEqual o.value(), [0, 1]

  it 'should add to the middle', ->
    o = new RObject([1, 4])
    o.splice 1, 0, 2, 3
    assert.deepEqual o.value(), [1, 2, 3, 4]

  it 'should add to the end', ->
    o = new RObject([1])
    o.splice 1, 0, 2, 3
    assert.deepEqual o.value(), [1, 2, 3]

  it 'should fire add event when items are added', ->
    o = new RObject([1, 4])
    adds = 0
    o.on 'add', -> adds++
    o.splice 1, 0, 2, 3
    assert.deepEqual adds, 1

  it 'should not fire add event when no items are added', ->
    o = new RObject([1, 4])
    adds = 0
    o.on 'add', -> adds++
    o.splice 1, 0
    assert.deepEqual adds, 0

  it 'add event should contain items added', ->
    o = new RObject([1, 4])
    addedItems = null
    o.on 'add', (items) -> addedItems = items
    o.splice 1, 0, 2, 3
    assert.deepEqual addedItems.map((o) -> o.value()), [2, 3]

  it 'add event should contain index of items added', ->
    o = new RObject([1, 4])
    addIndex = null
    o.on 'add', (items, {index}) -> addIndex = index
    o.splice 1, 0, 2, 3
    assert.deepEqual addIndex, 1

  it 'should update array before firing add event when an item is added', ->
    o = new RObject([1, 4])
    addValue = null
    o.on 'add', -> addValue = _clone o.value()
    o.splice 1, 0, 2, 3
    assert.deepEqual addValue, [1, 2, 3, 4]


  it 'should remove the number of items specified', ->
    o = new RObject([1, 2])
    o.splice 0, 1
    assert.deepEqual o.value(), [2]

  it 'should remove the number of items specified at the specified index in the middle', ->
    o = new RObject([1, 2, 3, 4])
    o.splice 1, 2
    assert.deepEqual o.value(), [1, 4]

  it 'should remove the number of items specified at the specified index at the end', ->
    o = new RObject([1, 2, 3])
    o.splice 1, 2
    assert.deepEqual o.value(), [1]

  #todo: should return RObjects?
  #todo: might not return correct value if something has an RObject at spliced index
  it 'should return removed items', ->
    o = new RObject([1, 2, 3, 4])
    assert.deepEqual o.splice(1, 2), [2, 3]

  it 'should remove only the items after the index when the
      number to remove exceeds the length of the target', ->
    o = new RObject([1, 2, 3])
    o.splice 1, 4
    assert.deepEqual o.value(), [1]

  it 'should fire remove event when items are removed', ->
    o = new RObject([1, 2, 3, 4])
    removes = 0
    o.on 'remove', -> removes++
    o.splice 1, 2
    assert.deepEqual removes, 1

  it 'should not fire remove event when 0 items are removed', ->
    o = new RObject([1, 2, 3, 4])
    removes = 0
    o.on 'remove', -> removes++
    o.splice 1, 0
    assert.deepEqual removes, 0

  it 'remove event should contain items removed', ->
    o = new RObject([1, 2, 3, 4])
    removedItems = null
    o.on 'remove', (items) -> removedItems = items
    o.splice 1, 2
    assert.deepEqual removedItems.map((o) -> o.value()), [2, 3]

  it 'remove event should contain index of items removed', ->
    o = new RObject([1, 2, 3, 4])
    removeIndex = null
    o.on 'remove', (items, {index}) -> removeIndex = index
    o.splice 1, 2
    assert.deepEqual removeIndex, 1

  it 'remove event items should only contain the items removed when the
      number to remove exceeds the length of the target', ->
    o = new RObject([1, 2, 3])
    removedItems = null
    o.on 'remove', (items) -> removedItems = items
    o.splice 1, 4
    assert.deepEqual removedItems.map((o) -> o.value()), [2, 3]

  it 'should update array before firing remove event when an item is removed', ->
    o = new RObject([1, 2, 3, 4])
    removeValue = null
    o.on 'remove', -> removeValue = _clone o.value()
    o.splice 1, 2
    assert.deepEqual removeValue, [1, 4]


  it 'should add and remove in a single call', ->
    o = new RObject([1, 8, 6, 4])
    o.splice 1, 2, 2, 3
    assert.deepEqual o.value(), [1, 2, 3, 4]

  it 'should fire add and remove events before adding and removing items', ->
    o = new RObject([1, 8, 6, 4])
    removeValue = null
    addValue = null
    o.on 'remove', -> removeValue = _clone o.value()
    o.on 'add', -> addValue = _clone o.value()
    o.splice 1, 2, 2, 3
    assert.deepEqual removeValue, [1, 2, 3, 4]
    assert.deepEqual addValue, [1, 2, 3, 4]

  # this seems random but it's an edge case that was failing at one point
  it 'should splice in an RObject to the front of an array', ->
    o = new RObject([new RObject(2)])
    o.splice 0, 0, new RObject(1)
    assert.deepEqual o.value(), [1, 2]

  #todo: edge cases?


#todo: rerun fn if an RObject wasnt returned?
describe '#map()', ->
  inverse = (item) ->
    item.inverse()

  #todo: test multi adds/removes

  describe 'type: Array', ->
    it 'should map initial items', ->
      o = new RObject([1, 2])
      inversed = o.map inverse
      assert.deepEqual inversed.value(), [-1, -2]

    it 'should map item added later', ->
      o = new RObject([2])
      inversed = o.map inverse
      o.splice 0, 0, 1
      assert.deepEqual inversed.value(), [-1, -2]

    it 'should remove item from the child when item is removed from the parent', ->
      o = new RObject([1, 2, 3])
      inversed = o.map inverse
      o.splice 1, 1
      assert.deepEqual inversed.value(), [-1, -3]

    it 'should set length of initial value', ->
      o = new RObject([2])
      inversed = o.map inverse
      o.splice 0, 0, 1
      assert.deepEqual inversed.length().value(), 2

    it 'should set length of items added later', ->
      o = new RObject([2])
      inversed = o.map inverse
      inversedLength = inversed.length()
      o.splice 0, 0, 1
      assert.deepEqual inversedLength.value(), 2

    it 'should maintain order of added items', ->
      o = new RObject([1, 3])
      inversed = o.map inverse
      o.splice 1, 0, 2
      assert.deepEqual inversed.value(), [-1, -2, -3]

    it 'should only call transform fn once when item is added', ->
      o = new RObject([1])
      transforms = 0
      inversed = o.map (item) ->
        transforms++
        item.inverse()

      transforms = 0
      o.splice 1, 0, new RObject(2)
      assert.strictEqual transforms, 1

    it 'should update when parent value changes', ->
      num = new RObject(1)
      o = new RObject([num])
      inversed = o.map inverse
      num.set(2)
      assert.deepEqual inversed.value(), [-2]

    it 'should not rerun transform fn when parent value changes', ->
      num = new RObject(1)
      o = new RObject([num])
      transforms = 0
      inversed = o.map (item) ->
        transforms++
        item.inverse()

      num.set(2)
      assert.strictEqual transforms, 1


    describe 'non-RObject returned from transform fn', ->
      it 'should transform initial items', ->
        o = new RObject([1, 2])
        inversed = o.map (item) ->
          -item.value()

        assert.deepEqual inversed.value(), [-1, -2]

      it 'should transform items added later', ->
        o = new RObject([])
        inversed = o.map (item) ->
          -item.value()

        o.splice 0, 0, 1, 2
        assert.deepEqual inversed.value(), [-1, -2]

      it 'should fire add event with RObject', ->
        o = new RObject([])
        inversed = o.map (item) ->
          -item.value()

        adds = []
        inversed.on 'add', (items) ->
          adds = items

        o.splice 0, 0, 1, 2
        assert.deepEqual adds.map((add) -> add.value()), [-1, -2]

  describe 'type: Other', ->
    it 'should return null', ->
      o = new RObject()
      inversed = o.map inverse

      assert.deepEqual inversed.value(), null

  #todo: dynamic changes to every type

  # it 'should handle dynamic type change', ->
  #   o = new RObject()
  #   inversed = o.map (item) ->
  #     item.inverse()

  #   o.set [3]
  #   assert.deepEqual inversed.value(), [-3]
  #   o.set null
  #   assert.deepEqual inversed.value(), null


#todo: refector to use 1 assert vvvvvvv
describe '#filter()', ->
  isEven = (num) ->
    num.mod(new RObject(2)).is(new RObject(0))

  describe 'type: Array', ->
    it 'should filter initial items', ->
      o = new RObject([4, 5, 6])
      evens = o.filter isEven
      assert.deepEqual evens.value(), [4, 6]

    it 'should filter added items', ->
      o = new RObject([4, 5, 6])
      evens = o.filter isEven
      o.add new RObject(7)
      assert.deepEqual evens.value(), [4, 6]
      o.add new RObject(8)
      assert.deepEqual evens.value(), [4, 6, 8]

    it 'should filter added items when more than one is added at a time', ->
      o = new RObject([4, 5, 6])
      evens = o.filter isEven
      o.add [new RObject(7), new RObject(8)]
      assert.deepEqual evens.value(), [4, 6, 8]

    it 'should filter added items and put them in the correct place when spliced', ->
      o = new RObject([1, 2, 4, 3, 3, 5, 9, 12])
      evens = o.filter isEven
      o.splice 5, 0, new RObject(7), new RObject(8), new RObject(9), new RObject(10)
      assert.deepEqual evens.value(), [2, 4, 8, 10, 12]

    it 'should filter added items and put them in the correct place when spliced at position 0', ->
      o = new RObject([3, 4])
      evens = o.filter isEven
      o.splice 0, 0, new RObject(2)
      assert.deepEqual evens.value(), [2, 4]

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
      assert.deepEqual evens.value(), [4, 6]

    it 'should always call back with an RObject', ->
      o = new RObject([3])
      isRObject = false
      evens = o.filter (val) ->
        isRObject = val instanceof RObject
        new RObject(true)

      assert.strictEqual isRObject, true

    it 'should update filter when given boolean changes', ->
      first = new RObject(3)
      o = new RObject([first])
      evens = o.filter isEven
      first.set 4
      assert.deepEqual evens.value(), [4]
      first.set 3
      assert.deepEqual evens.value(), []

    it 'should update filter when given boolean changes for dynamically added items', ->
      four = new RObject(4)
      o = new RObject([2, 3, 5, 6])
      evens = o.filter isEven
      o.splice 2, 0, four
      four.set 4
      assert.deepEqual evens.value(), [2, 4, 6]
      four.set 3
      assert.deepEqual evens.value(), [2, 6]
      # do it again to make sure it is releasing event listeners and stuff
      four.set 4
      assert.deepEqual evens.value(), [2, 4, 6]
      four.set 3
      assert.deepEqual evens.value(), [2, 6]

    it 'should maintain order of filtered arrays', ->
      o = new RObject([1, 2, 3, 4, 5, 6])
      evens = o.filter isEven
      o.at(3).set 11
      o.at(3).set 4
      assert.deepEqual evens.value(), [2, 4, 6]


  it 'should handle dynamic type change', ->
    o = new RObject()
    evens = o.filter isEven
    o.set [3, 4]
    assert.deepEqual evens.value(), [4]
    o.set null
    assert.deepEqual evens.value(), null


#todo: test event listener removal
# describe '#reduce()', ->
#   add = (prev, current) ->
#     prev.add current

#   describe 'type: Array', ->
#     it 'should run through items and give the result', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce (prev, current) ->
#         if prev.type().value() == 'empty'
#           prev.set 0
#         prev.add current
#       assert.strictEqual result.value(), 10

#     it 'should run through items and give the result starting with given inital value', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(8)
#       assert.strictEqual result.value(), 18

#     it 'should run through items and give the result starting with given inital value', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(0)
#       assert.strictEqual result.value(), 10

#     it 'should update reduced value when item is added to array', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(0)
#       o.splice 1, 0, new RObject(37)
#       assert.strictEqual result.value(), 47

#     it 'should update reduced value when multiple items are added to array', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(0)
#       o.splice 1, 0, new RObject(37), new RObject(74), new RObject(86)
#       assert.strictEqual result.value(), 207

#     it 'should update reduced value when item is removed from array', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(0)
#       o.splice 1, 1
#       assert.strictEqual result.value(), 8

#     it 'should update reduced value when multiple items are removed from array', ->
#       o = new RObject([ new RObject(1), new RObject(2), new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(0)
#       o.splice 1, 2
#       assert.strictEqual result.value(), 5

#     it 'should update reduced value when items change', ->
#       val = new RObject(2)
#       o = new RObject([ new RObject(1), val, new RObject(3), new RObject(4) ])
#       result = o.reduce add, new RObject(0)
#       val.set 39
#       assert.strictEqual result.value(), 47

#     it 'should update reduced value when given a subproperty', ->
#       o = new RObject([
#         new RObject({ name: 'JJ' })
#         new RObject({ name: 'John' })
#         new RObject({ name: 'Johan' })
#         new RObject({ name: 'Jackie' })
#       ])
#       result = o.reduce (prev, current) ->
#         prev.add current.prop('name').length()
#       , new RObject(0)
#       assert.strictEqual result.value(), 17

#     # it 'should update reduced value when given subproperty changes', ->
#     #   name = 'John'
#     #   o = new RObject([
#     #     { name: 'JJ' }
#     #     { name: name }
#     #     { name: 'Johan' }
#     #     { name: 'Jackie' }
#     #   ])
#     #   result = o.reduce (prev, current) ->
#     #     prev.add current.prop('name').length()
#     #   , new RObject(0)
#     #   o.at(1).set 'Johnathan'
#     #   assert.strictEqual result.value(), 22

#   describe 'type: Other', ->
#     everyTypeExcept 'array', (o) ->
#       result = o.reduce ->
#       assert.strictEqual result.value(), null


describe '#subscribe()', ->
  describe 'type: Array', ->
    it 'should call fn for every item that is already in the array', ->
      o = new RObject([1, 2, 3])
      calls = []
      o.subscribe (item) ->
        calls.push item

      assert.strictEqual calls.length, 3
      assert.deepEqual (calls.map((o) -> o.value())), [1, 2, 3]

    it 'should call fn for items dynamically added', ->
      o = new RObject([])
      o.subscribe (item) ->
        calls?.push item
      calls = []
      o.splice 0, 0, new RObject(1), new RObject(2), new RObject(3)

      assert.strictEqual calls.length, 3
      assert.deepEqual (calls.map((o) -> o.value())), [1, 2, 3]

    it 'should include indexes of items added', ->
      o = new RObject([1, 2, 4, 5])
      calls = []
      indexes = []
      o.subscribe (item, {index}) ->
        calls.push item
        indexes.push index

      o.splice 1, 1, new RObject(2), new RObject(3)

      assert.strictEqual calls.length, 6
      assert.deepEqual (calls.map((o) -> o.value())), [1, 2, 4, 5, 2, 3]
      assert.deepEqual indexes, [0, 1, 2, 3, 1, 2]

    it 'should call fn when type is dynamically changed to an array', ->
      everyTypeExcept 'array', (o) ->
        calls = []
        indexes = []
        o.subscribe (item, {index}) ->
          calls.push item
          indexes.push index

        o.set [1, 2]
        assert.strictEqual calls.length, 2
        assert.deepEqual indexes, [0, 1]

    it 'should call fn when type is dynamically changed to array from another array', ->
      o = new RObject([1, 2])

      calls = []
      indexes = []
      o.subscribe (item, {index}) ->
        calls.push item
        indexes.push index

      assert.strictEqual calls.length, 2

      o.set [3, 4]

      assert.deepEqual calls.map((o) -> o.value()), [1, 2, 3, 4]
      assert.deepEqual indexes, [0, 1, 0, 1]

  describe 'type: Other', ->
    it 'should never call fn unless type is array', ->
      everyTypeExcept 'array', (other) ->
        o = new RObject()
        calls = 0
        o.subscribe ->
          calls++
        o.set other.value()
        assert.strictEqual calls, 0


# describe '#add()', ->
#   it 'should add item and trigger add event', ->
#     o = new RObject([])
#     one = new RObject(1)
#     addTriggered = false
#     o.on 'add', (items, {index}) ->
#       assert.strictEqual items[0], 1, 'add event should include added item'
#       assert.strictEqual o.length().value(), 1, 'array length should be updated by the time add event is triggered'
#       assert.strictEqual index, 0, 'add event should include index'
#       addTriggered = true

#     o.add 1
#     assert.strictEqual addTriggered, true
#     assert.deepEqual o.value(), [1]

#   it 'should add at the index if one is specified', ->
#     o = new RObject([5, 6, 7])
#     addTriggered = false
#     o.on 'add', (items, {index}) ->
#       assert.strictEqual items[0], 1, 'add event should include added item'
#       assert.strictEqual o.length().value(), 4, 'array length should be updated by the time add event is triggered'
#       assert.strictEqual index, 2, 'add event should include index'
#       addTriggered = true

#     o.add 1, {index: 2}
#     assert.strictEqual addTriggered, true
#     assert.deepEqual o.value(), [5, 6, 1, 7]

#   it 'should allow adding multiple items via Array', ->
#     o = new RObject([3, 8, 9])
#     addsTriggered = 0
#     o.on 'add', (items, {index}) ->
#       assert.deepEqual items, [4, 5, 6, 7], 'add event should include added items'
#       assert.strictEqual o.length().value(), 7, 'array length should be updated by the time add event is triggered'
#       assert.strictEqual index, 1, 'add event should include index'
#       addsTriggered++

#     o.add [4, 5, 6, 7], {index: 1}
#     assert.deepEqual o.value(), [3, 4, 5, 6, 7, 8, 9]
#     assert.strictEqual addsTriggered, 1

describe '#add()', ->
  o1 = new RObject(5)
  o2 = new RObject(6)
  result = o1.add(o2)
  assert.strictEqual result.value(), 11
  o1.set 12
  assert.strictEqual result.value(), 18, "it should update when first value is changed"
  o2.set 33
  assert.strictEqual result.value(), 45, "it should update when second value is changed"
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"


# describe '#subtract()', ->
#   o1 = new RObject(5)
#   o2 = new RObject(6)
#   result = o1.subtract(o2)
#   assert.strictEqual result.value(), -1, "it should subtract the initial values"
#   o1.set 12
#   assert.strictEqual result.value(), 6, "it should update when first value is changed"
#   o2.set 33
#   assert.strictEqual result.value(), -21, "it should update when second value is changed"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"

#   it 'should work on a proxy', ->
#     o1 = new RObject(new RObject(8))
#     o2 = new RObject(5)
#     result = o1.subtract o2
#     assert.strictEqual result.value(), 3

#   it 'proxy should update when it changes', ->
#     o1 = new RObject(new RObject(8))
#     o2 = new RObject(5)
#     result = o1.subtract o2
#     o1.set 9
#     assert.strictEqual result.value(), 4

#   it 'proxy should give correct value when proxy turns to a normal number', ->
#     o1 = new RObject(new RObject(8))
#     o2 = new RObject(5)
#     result = o1.subtract o2
#     o1.refSet 9
#     assert.strictEqual result.value(), 4

#   it 'proxy should give correct value when normal number turns to a proxy', ->
#     o1 = new RObject(8)
#     o2 = new RObject(5)
#     result = o1.subtract o2
#     o1.set new RObject(9)
#     assert.strictEqual result.value(), 4





describe '#multiply()', ->
  o1 = new RObject(5)
  o2 = new RObject(6)
  result = o1.multiply(o2)
  assert.strictEqual result.value(), 30, "it should multiply the initial values"
  o1.set 12
  assert.strictEqual result.value(), 72, "it should update when first value is changed"
  o2.set 33
  assert.strictEqual result.value(), 396, "it should update when second value is changed"
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"


describe '#divide()', ->
  o1 = new RObject(-12)
  o2 = new RObject(6)
  result = o1.divide(o2)
  assert.strictEqual result.value(), -2, "it should divide the initial values"
  o1.set 36
  assert.strictEqual result.value(), 6, "it should update when first value is changed"
  o2.set 3
  assert.strictEqual result.value(), 12, "it should update when second value is changed"
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"

  it 'should be Infinity when dividing by 0', ->
    result = new RObject(12).divide(new RObject(0))
    assert.strictEqual result.value(), Infinity


describe '#mod()', ->
  o1 = new RObject(1046)
  o2 = new RObject(100)
  result = o1.mod(o2)
  assert.strictEqual result.value(), 46, "it should mod the initial values"
  o1.set 1073
  assert.strictEqual result.value(), 73, "it should update when first value is changed"
  o2.set 110
  assert.strictEqual result.value(), 83, "it should update when second value is changed"
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"


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
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"


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
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"


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
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"


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
  assert.strictEqual result instanceof RObject, true, "it should return an RObject"



#todo: array concat
describe '#concat()', ->
  it 'should concat the initial values', ->
    o1 = new RObject('foo')
    o2 = new RObject('bar')
    assert.strictEqual o1.concat(o2).value(), 'foobar'

  it 'should return an RObject', ->
    o1 = new RObject('foo')
    o2 = new RObject('bar')
    assert.strictEqual o1.concat(o2) instanceof RObject, true

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
    assert.strictEqual o1.indexOf(o2) instanceof RObject, true

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

#todo: test index as non robject and robject
describe '#at()', ->
  it 'should give item at the specified index', ->
    a = new RObject([1, 2, 3])
    assert.strictEqual a.at(0).value(), 1
    assert.strictEqual a.at(1).value(), 2
    assert.strictEqual a.at(2).value(), 3

  it 'should update item at index when array is changed', ->
    a = new RObject([1, 3])
    atIndex1 = a.at(1)
    a.splice 1, 0, 2
    assert.strictEqual atIndex1.value(), 2

  it 'should update item at index when index is changed', ->
    index = new RObject(1)
    a = new RObject([1, 2, 3])
    atIndex = a.at(index)
    assert.strictEqual atIndex.value(), 2
    index.set 2
    assert.strictEqual atIndex.value(), 3


#when object passed to constructor is changed later but before .prop is called, does it need to use the constructed value? (lazily create propRefs)
describe '#prop()', ->
  describe 'type: Object', ->
    it 'should allow getting properties of passed in the constructor', ->
      o = new RObject { eight: '8', nine: '9' }
      assert.strictEqual '8', o.prop('eight').value()
      assert.strictEqual '9', o.prop('nine').value()

    it 'should allow setting properties and getting them back', ->
      o = new RObject {}
      o.prop 'great', 'job'
      assert.strictEqual 'job', o.prop('great').value()

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
        assert.strictEqual null, prop.value()

  it 'should handle dynamic type change', ->
    everyType (o) ->
      prop = o.prop 'as'
      o.set {as: 'df'}
      assert.strictEqual 'df', prop.value()
      o.set 5
      assert.strictEqual null, prop.value()

  it 'should switch to new property when name changes', ->
    o = new RObject({ a: 'aaa', b: 'bbb' })
    propName = new RObject('a')
    result = o.prop propName
    propName.set 'b'
    assert.strictEqual result.value(), 'bbb'
