
assert = require 'assert'
_clone = require 'lodash.clone'

RObject = require '../src/RObject'

# never ever ever use assert.equal, 8 == ['8'] // true
# everything that returns an RObject should handle type changes of self
# make sure to test for dynamic changing values
# make sure to test for proxy functionality

#todo: test empty cases

# #watch()

#todo: test refValue

#todo: test accessing array items via prop
#todo: add test for cyclical object
#todo: add test for cyclical array
#todo: test for own of value

#todo: test event methods

#todo: make sure all methods are chainable

#todo: #combine() or _ it

#todo: all ref* methods

#todo: original object shouldnt be modified other than being syncd to

#todo:  make sure all methods work with multi-adds/removes

#todo: type change event is fired before value changes

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

  it 'should change the value of the proxy when proxy value is changed', ->
    original = new RObject()
    proxy = new RObject(original)
    proxy.set 6
    assert.strictEqual proxy.value(), 6

  it 'should change the value of the original when proxy value changes', ->
    original = new RObject()
    proxy = new RObject(original)
    proxy.set 6
    assert.strictEqual original.value(), 6

  it 'should change the value of the proxy when original value changes', ->
    original = new RObject()
    proxy = new RObject(original)
    original.set 6
    assert.strictEqual proxy.value(), 6

  it 'should change value when set to a value that is == to the thing being set', ->
    o = new RObject(8)
    o.set '8'
    assert.strictEqual o.value(), '8'

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

  describe 'add event', ->
    it 'should not fire when set to the same array value', ->
      val = [1, 2, 3]
      o = new RObject(val)
      adds = 0
      o.on 'add', -> adds++
      o.set val
      assert.strictEqual adds, 0

  describe 'remove event', ->
    it 'should not fire when set to the same array value', ->
      val = [1, 2, 3]
      o = new RObject(val)
      removes = 0
      o.on 'add', -> removes++
      o.set val
      assert.strictEqual removes, 0

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
      o.splice 1, 0, 2, 3
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
      o.prop('cat').set 'mouse'
      assert.strictEqual o.value().cat, 'mouse'

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

describe '#length()', ->
  it 'should update length when value changes to an array', ->
    o = new RObject()
    o.set [1, 2, 3, 4, 5]
    assert.strictEqual o.length().value(), 5

  it 'should update length when value changes to a string', ->
    o = new RObject()
    o.set 'barbaque'
    assert.strictEqual o.length().value(), 8

  it 'should update existing length object', ->
    o = new RObject()
    len = o.length()
    o.set [1, 2, 3, 4, 5]
    assert.strictEqual len.value(), 5

  it 'should give empty for type number', ->
    assert.strictEqual new RObject(5).length().value(), null

  it 'should give empty for type object', ->
    assert.strictEqual new RObject({a: 'b'}).length().value(), null

  it 'should give empty for type empty', ->
    assert.strictEqual new RObject().length().value(), null

  it 'should give empty for type boolean', ->
    assert.strictEqual new RObject(true).length().value(), null

  it 'should give length of proxy object', ->
    assert.strictEqual new RObject(new RObject('asdf')).length().value(), 4

  it 'should give empty when dynamically changing to a number', ->
    o = new RObject('bbq')
    len = o.length()
    o.set(6)
    assert.strictEqual len.value(), null

  it 'should give empty when dynamically changing to a object', ->
    o = new RObject('bbq')
    len = o.length()
    o.set({})
    assert.strictEqual len.value(), null

  it 'should give empty when dynamically changing to a empty', ->
    o = new RObject('bbq')
    len = o.length()
    o.set(null)
    assert.strictEqual len.value(), null

  it 'should give empty when dynamically changing to a boolean', ->
    o = new RObject('bbq')
    len = o.length()
    o.set(true)
    assert.strictEqual len.value(), null

  it 'should update length when created with an array', ->
    o = new RObject('barbaque')
    assert.strictEqual o.length().value(), 8

  it 'should update length when created with an array', ->
    o = new RObject([1, 2, 3, 4, 5])
    assert.strictEqual o.length().value(), 5

  it 'should update length when value changes from a type with length to another type with length', ->
    o = new RObject('barbaque')
    o.set [1, 2, 3, 4, 5]
    assert.strictEqual o.length().value(), 5

  it 'should update length before change event when value changes to an array', ->
    o = new RObject()
    len = o.length()
    changeLength = null
    o.on 'change', ->
      changeLength = len.value()
    o.set [1, 2, 3, 4, 5]
    assert.strictEqual changeLength, 5

  it 'should update length before change event when value changes to a string', ->
    o = new RObject()
    len = o.length()
    changeLength = null
    o.on 'change', ->
      changeLength = len.value()
    o.set 'barbaque'
    assert.strictEqual changeLength, 8

  it 'should update value before length change event for strings', ->
    o = new RObject('asd')
    changeValue = null
    o.length().on 'change', ->
      changeValue = o.value()
    o.set 'asdf'
    assert.strictEqual changeValue, 'asdf'

  it 'should update value before length change event for arrays', ->
    o = new RObject([1, 2, 3])
    changeValue = null
    o.length().on 'change', ->
      changeValue = o.value()
    o.set [1, 2, 3, 4]
    assert.deepEqual changeValue, [1, 2, 3, 4]

  it 'should update when value changes to a proxy', ->
    o = new RObject('bbq')
    length = o.length()
    o.set new RObject('waaah')
    assert.strictEqual length.value(), 5

  it 'should fire change event when value changes to a proxy', ->
    o = new RObject('bbq')
    changes = 0
    o.length().on 'change', -> changes++
    o.set new RObject('waaah')
    assert.strictEqual changes, 1
  # do we need to worry about event fire and change order?

  it 'should update when proxy value changes', ->
    child = new RObject('123')
    parent = new RObject(child)
    length = parent.length()
    child.set '12345'
    assert.strictEqual length.value(), 5

  it 'should update value changes from proxy to proxy', ->
    child = new RObject('bbq')
    parent = new RObject(child)
    newChild = new RObject('123456')
    length = parent.length()
    parent.refSet newChild
    assert.strictEqual length.value(), 6

  it 'should fire change event when value changes from proxy to proxy', ->
    child = new RObject('bbq')
    parent = new RObject(child)
    newChild = new RObject('123456')
    changes = 0
    parent.length().on 'change', -> changes++
    parent.refSet newChild
    assert.strictEqual changes, 1

  it 'should update when changing from a proxy to a string', ->
    o = new RObject new RObject('bbq')
    len = o.length()
    o.refSet('lolz')
    assert.strictEqual len.value(), 4

  it 'should update when changing from a proxy to an array', ->
    o = new RObject new RObject('bbq')
    len = o.length()
    o.refSet([1, 2, 3, 4])
    assert.strictEqual len.value(), 4

  it 'should update when changing from a proxy to empty', ->
    o = new RObject new RObject('bbq')
    len = o.length()
    o.refSet(null)
    assert.strictEqual len.value(), null


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

  it 'should work on a proxy array', ->
    o = new RObject new RObject([1, 8, 6, 4])
    o.splice 1, 2, 2, 3
    assert.deepEqual o.value(), [1, 2, 3, 4]

  # this seems random but it's an edge case that was failing at one point
  it 'should splice in an RObject to the front of an array', ->
    o = new RObject([new RObject(2)])
    o.splice 0, 0, new RObject(1)
    assert.deepEqual o.value(), [1, 2]


describe '#at()', ->

  it 'should give empty for an empty index', ->
    assert.strictEqual new RObject([1]).at(null).value(), null

  it 'should give empty for a string index', ->
    assert.strictEqual new RObject([1]).at('asd').value(), null

  it 'should give empty for a boolean index', ->
    assert.strictEqual new RObject([1]).at(true).value(), null

  it 'should give empty for an object index', ->
    assert.strictEqual new RObject([1]).at({a: 'lol'}).value(), null

  it 'should give empty for an array type index', ->
    assert.strictEqual new RObject([1]).at([0]).value(), null

  it 'should give empty for a string index when the string contains a number', ->
    assert.strictEqual new RObject([1]).at('0').value(), null

  it 'should give empty for a dynamic string index when the string contains a number', ->
    o = new RObject([1, 2])
    i = new RObject 0
    val = o.at i
    i.set '1'
    assert.strictEqual val.value(), null

  it 'should give empty when accessing a non existing element', ->
    assert.strictEqual new RObject([1, 2, 3]).at(10).value(), null

  describe 'types', ->
    it 'should give correct value for array value in the middle of the array', ->
      o = new RObject([1, 2, 3])
      assert.strictEqual o.at(1).value(), 2

    it 'should give correct value for array value at index 0', ->
      o = new RObject([1, 2, 3])
      assert.strictEqual o.at(0).value(), 1

    it 'should give correct value for array value at the end of the array', ->
      o = new RObject([1, 2, 3])
      assert.strictEqual o.at(2).value(), 3

    it 'should give correct value for non-array value', ->
      o = new RObject('abcd')
      assert.strictEqual o.at(1).value(), null

    it 'should give correct value for proxy array value', ->
      o = new RObject new RObject([1, 2, 3])
      assert.strictEqual o.at(1).value(), 2

    it 'should give correct value for proxy non-array value', ->
      o = new RObject new RObject('abcd')
      assert.strictEqual o.at(1).value(), null

    it 'should give correct value after changing from array to array', ->
      o = new RObject(['a', 'b', 'q'])
      val = o.at(1)
      o.refSet [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from array to non-array', ->
      o = new RObject([1, 2, 3])
      val = o.at(1)
      o.set 'abcd'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from array to proxy array', ->
      o = new RObject(['a', 'b', 'q'])
      val = o.at(1)
      o.refSet new RObject [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from array to proxy non-array', ->
      o = new RObject([1, 2, 3])
      val = o.at(1)
      o.set new RObject 'abcd'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from non-array to array', ->
      o = new RObject('abcd')
      val = o.at(1)
      o.set [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from non-array to non-array', ->
      o = new RObject('abcd')
      val = o.at(1)
      o.set 'bbq'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from non-array to proxy array', ->
      o = new RObject('abcd')
      val = o.at(1)
      o.set new RObject [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from non-array to proxy non-array', ->
      o = new RObject('abcd')
      val = o.at(1)
      o.set new RObject 'bbq'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy array to array', ->
      o = new RObject new RObject(['a', 'b', 'c'])
      val = o.at(1)
      o.refSet [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from proxy array to non-array', ->
      o = new RObject new RObject(['a', 'b', 'c'])
      val = o.at(1)
      o.refSet 'asdf'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy array to proxy array', ->
      o = new RObject new RObject(['a', 'b', 'c'])
      val = o.at(1)
      o.refSet new RObject [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from proxy array to proxy non-array', ->
      o = new RObject new RObject(['a', 'b', 'c'])
      val = o.at(1)
      o.refSet new RObject 'asdf'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy non-array to array', ->
      o = new RObject new RObject('qwerty')
      val = o.at(1)
      o.refSet [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from proxy non-array to non-array', ->
      o = new RObject new RObject('qwerty')
      val = o.at(1)
      o.refSet 'asdf'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy non-array to proxy array', ->
      o = new RObject new RObject('qwerty')
      val = o.at(1)
      o.refSet new RObject [1, 2, 3]
      assert.strictEqual val.value(), 2

    it 'should give correct value after changing from proxy non-array to proxy non-array', ->
      o = new RObject new RObject('qwerty')
      val = o.at(1)
      o.refSet new RObject 'asdf'
      assert.strictEqual val.value(), null

  describe 'objects', ->
    it 'should not give value of object with the same name', ->
      assert.strictEqual new RObject({0: 'lol'}).at(0).value(), null

    it 'should not give value of object with the same name when value changes to object', ->
      o = new RObject([1, 2, 3])
      val = o.at(0)
      o.set {0: 'lol'}
      assert.strictEqual val.value(), null

  describe 'array mutations', ->
    it 'should update item at index when value is replaced', ->
      o = new RObject([1, 3])
      atIndex1 = o.at(1)
      o.splice 1, 0, 2
      assert.strictEqual atIndex1.value(), 2

    it 'should clear result when item at index is shifted', ->
      o = new RObject([1, 2, 3])
      atIndex1 = o.at(1)
      o.splice 1, 1
      assert.strictEqual atIndex1.value(), 3

    it 'should clear result when item at index goes away', ->
      o = new RObject([1, 2, 3])
      atIndex1 = o.at(1)
      o.splice 1, 2
      assert.strictEqual atIndex1.value(), null

    it 'should clear result when item is added at index', ->
      o = new RObject([1])
      atIndex1 = o.at(1)
      o.splice 1, 0, 2, 3
      assert.strictEqual atIndex1.value(), 2

    it 'should update item at index when value is replaced on proxy value', ->
      o = new RObject new RObject([1, 3])
      atIndex1 = o.at(1)
      o.splice 1, 0, 2
      assert.strictEqual atIndex1.value(), 2

    it 'should clear result when item at index is shifted on proxy value', ->
      o = new RObject new RObject([1, 2, 3])
      atIndex1 = o.at(1)
      o.splice 1, 1
      assert.strictEqual atIndex1.value(), 3

    it 'should clear result when item at index goes away on proxy value', ->
      o = new RObject new RObject([1, 2, 3])
      atIndex1 = o.at(1)
      o.splice 1, 2
      assert.strictEqual atIndex1.value(), null

    it 'should clear result when item is added at index on proxy value', ->
      o = new RObject new RObject([1])
      atIndex1 = o.at(1)
      o.splice 1, 0, 2, 3
      assert.strictEqual atIndex1.value(), 2

  describe 'changing index', ->
    it 'should update to new value when index changes', ->
      o = new RObject [1, 2, 3, 4]
      i = new RObject 1
      val = o.at i
      i.set 2
      assert.strictEqual val.value(), 3

    it 'should update to new value when proxy type index changes', ->
      o = new RObject [1, 2, 3, 4]
      i = new RObject new RObject 1
      val = o.at i
      i.set 2
      assert.strictEqual val.value(), 3

    it 'should update to empty when index to non-number', ->
      o = new RObject [1, 2, 3, 4]
      i = new RObject 1
      val = o.at i
      i.set 'bbq'
      assert.strictEqual val.value(), null

    it 'should update to new value when index changes with a proxy value', ->
      o = new RObject new RObject [1, 2, 3, 4]
      i = new RObject 1
      val = o.at i
      i.set 2
      assert.strictEqual val.value(), 3

    it 'should update to new value when index and array changes', ->
      o = new RObject [1, 2, 3, 4, 5]
      i = new RObject 1
      val = o.at i
      i.set 2
      o.splice 1, 2
      assert.strictEqual val.value(), 5

    it 'should update to new value when array and index changes', ->
      o = new RObject [1, 2, 3, 4, 5]
      i = new RObject 1
      val = o.at i
      o.splice 1, 2
      i.set 2
      assert.strictEqual val.value(), 5

    it 'should update to new value when index and array changes on a proxy value', ->
      o = new RObject new RObject [1, 2, 3, 4, 5]
      i = new RObject 1
      val = o.at i
      i.set 2
      o.splice 1, 2
      assert.strictEqual val.value(), 5

    it 'should update to new value when array and index changes on a proxy value', ->
      o = new RObject new RObject [1, 2, 3, 4, 5]
      i = new RObject 1
      val = o.at i
      o.splice 1, 2
      i.set 2
      assert.strictEqual val.value(), 5

  describe 'proxy', ->
    it 'should change when value through proxy value changes', ->
      mid = new RObject(2)
      o = new RObject new RObject([1, mid, 4])
      at1 = o.at(1)
      mid.set(3)
      assert.strictEqual at1.value(), 3

    it 'should change proxy value when value changes', ->
      mid = new RObject(2)
      o = new RObject new RObject([1, mid, 4])
      o.at(1).set(3)
      assert.strictEqual mid.value(), 3

  # I'm not sure if these are too "internal" to be testing but
  # I think it could cause issues for users if it changes

  it 'should not change first level nested RObject when index changes', ->
    o = new RObject([1, 2, 3])
    i = new RObject 1
    atIndex1 = o.at(i).refValue()
    i.set 2
    assert.strictEqual atIndex1.value(), 2

  it 'should not change the second level nexted RObject when array is mutated', ->
    o = new RObject([1, 2, 3])
    atIndex1 = o.at(1).refValue().refValue()
    o.splice 1, 1
    assert.strictEqual atIndex1.value(), 2

#when object passed to constructor is changed later but before .prop is called, does it need to use the constructed value? (lazily create propRefs)
describe '#prop()', ->
  it 'should give empty for an empty key', ->
    assert.strictEqual new RObject({a: 'aaa'}).prop(null).value(), null

  it 'should give empty for a number key', ->
    assert.strictEqual new RObject({a: 'aaa'}).prop(123).value(), null

  it 'should give empty for a boolean key', ->
    assert.strictEqual new RObject({a: 'aaa'}).prop(true).value(), null

  it 'should give empty for an object type key', ->
    assert.strictEqual new RObject({a: 'aaa'}).prop({a: 'lol'}).value(), null

  it 'should give empty for an array type key', ->
    assert.strictEqual new RObject({a: 'aaa'}).prop([0]).value(), null

  it 'should give empty for a number key when the number contains a valid string key', ->
    assert.strictEqual new RObject({0: 'aaa'}).prop(0).value(), null

  it 'should give empty for a dynamic string index when the string contains a number', ->
    o = new RObject({0: 'aaa', 1: 'bbb'})
    i = new RObject '0'
    val = o.prop i
    i.set 1
    assert.strictEqual val.value(), null

  it 'should give empty when accessing a non existing key', ->
    assert.strictEqual new RObject({a: 'aaa'}).prop('b').value(), null

  describe 'types', ->
    it 'should give correct value for givrn key', ->
      o = new RObject({a: 'aaa', b: 'bbb'})
      assert.strictEqual o.prop('b').value(), 'bbb'

    it 'should give correct value for non-object value', ->
      o = new RObject('abcd')
      assert.strictEqual o.prop('a').value(), null

    it 'should give correct value for proxy object value', ->
      o = new RObject new RObject({a: 'aaa'})
      assert.strictEqual o.prop('a').value(), 'aaa'

    it 'should give correct value for proxy non-array value', ->
      o = new RObject new RObject('abcd')
      assert.strictEqual o.prop('a').value(), null

    it 'should give correct value after changing from object to object', ->
      o = new RObject({b: 'bbb'})
      val = o.prop('b')
      o.refSet {b: 'bbbbb'}
      assert.strictEqual val.value(), 'bbbbb'

    it 'should give correct value after changing from object to non-object', ->
      o = new RObject({a: 'aaa'})
      val = o.prop('a')
      o.set 'abcd'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from object to proxy object', ->
      o = new RObject({a: 'aaa'})
      val = o.prop('a')
      o.refSet new RObject {a: 'aaaaa'}
      assert.strictEqual val.value(), 'aaaaa'

    it 'should give correct value after changing from object to proxy non-object', ->
      o = new RObject({a: 'aaa'})
      val = o.prop('a')
      o.set new RObject 'abcd'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from non-object to object', ->
      o = new RObject('abcd')
      val = o.prop 'a'
      o.set {a: 'aaa'}
      assert.strictEqual val.value(), 'aaa'

    it 'should give correct value after changing from non-object to non-object', ->
      o = new RObject('abcd')
      val = o.prop('a')
      o.set 'bbq'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from non-object to proxy object', ->
      o = new RObject('abcd')
      val = o.prop('a')
      o.set new RObject {a: 'aaa'}
      assert.strictEqual val.value(), 'aaa'

    it 'should give correct value after changing from non-object to proxy non-object', ->
      o = new RObject('abcd')
      val = o.prop(1)
      o.set new RObject 'bbq'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy object to object', ->
      o = new RObject new RObject({a: 'aaa'})
      val = o.prop('a')
      o.refSet {a: 'aaaaa'}
      assert.strictEqual val.value(), 'aaaaa'

    it 'should give correct value after changing from proxy object to non-object', ->
      o = new RObject new RObject({a: 'aaa'})
      val = o.prop('a')
      o.refSet 'asdf'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy object to proxy object', ->
      o = new RObject new RObject({a: 'aaa'})
      val = o.prop('a')
      o.refSet new RObject {a: 'aaaaa'}
      assert.strictEqual val.value(), 'aaaaa'

    it 'should give correct value after changing from proxy object to proxy non-object', ->
      o = new RObject new RObject({a: 'aaa'})
      val = o.prop('a')
      o.refSet new RObject 'asdf'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy non-object to object', ->
      o = new RObject new RObject('qwerty')
      val = o.prop('a')
      o.refSet {a: 'aaa'}
      assert.strictEqual val.value(), 'aaa'

    it 'should give correct value after changing from proxy non-object to non-object', ->
      o = new RObject new RObject('qwerty')
      val = o.prop('a')
      o.refSet 'asdf'
      assert.strictEqual val.value(), null

    it 'should give correct value after changing from proxy non-object to proxy object', ->
      o = new RObject new RObject('qwerty')
      val = o.prop('a')
      o.refSet new RObject {a: 'aaa'}
      assert.strictEqual val.value(), 'aaa'

    it 'should give correct value after changing from proxy non-object to proxy non-object', ->
      o = new RObject new RObject('qwerty')
      val = o.prop('a')
      o.refSet new RObject 'asdf'
      assert.strictEqual val.value(), null

  describe 'objects', ->
    it 'should not give value of array items with the same name', ->
      assert.strictEqual new RObject(['lol']).prop('0').value(), null

    it 'should not give value of array item with the same name when value changes to array', ->
      o = new RObject({0: 'hi'})
      val = o.prop('0')
      o.set ['lol']
      assert.strictEqual val.value(), null

  describe 'changing key', ->
    it 'should update to new value when key changes', ->
      o = new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      key.set 'b'
      assert.strictEqual val.value(), 'bbb'

    it 'should update to new value when proxy type key changes', ->
      o = new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject new RObject 'a'
      val = o.prop key
      key.set 'b'
      assert.strictEqual val.value(), 'bbb'

    it 'should update to empty when key to non-number', ->
      o = new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      key.set 12
      assert.strictEqual val.value(), null

    it 'should update to new value when key changes with a proxy value', ->
      o = new RObject new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      key.set 'b'
      assert.strictEqual val.value(), 'bbb'

    it 'should update to new value when key and object changes', ->
      o = new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      key.set 'b'
      o.set {a: 'aaaaa', b: 'bbbbb'}
      assert.strictEqual val.value(), 'bbbbb'

    it 'should update to new value when object and key changes', ->
      o = new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      o.set {a: 'aaaaa', b: 'bbbbb'}
      key.set 'b'
      assert.strictEqual val.value(), 'bbbbb'

    it 'should update to new value when key and object changes on a proxy value', ->
      o = new RObject new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      key.set 'b'
      o.set {a: 'aaaaa', b: 'bbbbb'}
      assert.strictEqual val.value(), 'bbbbb'

    it 'should update to new value when object and key changes on a proxy value', ->
      o = new RObject new RObject {a: 'aaa', b: 'bbb'}
      key = new RObject 'a'
      val = o.prop key
      o.set {a: 'aaaaa', b: 'bbbbb'}
      key.set 'b'
      assert.strictEqual val.value(), 'bbbbb'

  describe 'proxy', ->
    it 'should change when value through proxy value changes', ->
      bs = new RObject 'bbb'
      o = new RObject new RObject {b: bs}
      bProp = o.prop 'b'
      bs.set 'bbbbb'
      assert.strictEqual bProp.value(), 'bbbbb'

    it 'should change proxy value when value changes', ->
      bs = new RObject 'bbb'
      o = new RObject new RObject {b: bs}
      bProp = o.prop('b').set 'bbbbb'
      assert.strictEqual bs.value(), 'bbbbb'

  # I'm not sure if these are too "internal" to be testing but
  # I think it could cause issues for users if it changes

  it 'should not change first level nested RObject when index changes', ->
    o = new RObject {a: 'aaa', b: 'bbb'}
    key = new RObject 'a'
    val = o.prop(key).refValue()
    key.set 'b'
    assert.strictEqual val.value(), 'aaa'







describe '#combine', ->
  it 'should run cb with value immeditely', ->
    value = null
    new RObject('asdf').combine (val) ->
      value = val
    assert.equal value, 'asdf'

   it 'should rerun cb when self value changes', ->
    values = []
    o = new RObject 'asdf'
    o.combine (val) ->
      values.push val
    o.set 'bbq'
    assert.equal values[1], 'bbq'

  it 'should run cb with second value', ->
    value = null
    new RObject('asdf').combine new RObject('bbq'), (val, val2) ->
      value = val2
    assert.equal value, 'bbq'

  it 'should rerun cb when passed value changes', ->
    values = []
    o = new RObject 'yummy'
    new RObject('asdf').combine o, (val, val2) ->
      values.push val2
    o.set 'bbq'
    assert.equal values[1], 'bbq'

  it 'should run cb with many values', ->
    value = null
    new RObject('asdf').combine new RObject('bbq'), new RObject('bbq'), new RObject('bbq'), new RObject('bbq'), new RObject('yolo'), (val, val2, val3, val4, val5, val6) ->
      value = val6
    assert.equal value, 'yolo'

# relies on #concat for live updating stuff
describe '#concat()', ->
  #todo: arrays and fixure out how to switch between arrays/string
  describe 'strings', ->
    it 'should concat a string to a rstring', ->
      assert.strictEqual new RObject('asdf').concat(new RObject('bbq')).value(), 'asdfbbq'


describe '#subtract()', ->
  it 'subtracts numbers', ->
    assert.strictEqual new RObject(8).subtract(new RObject(2)).value(), 6

  it 'subtracts negative result', ->
    assert.strictEqual new RObject(3).subtract(new RObject(4)).value(), -1

describe '#multiply()', ->
  it 'multiplys numbers', ->
    assert.strictEqual new RObject(3).multiply(new RObject(4)).value(), 12

describe '#divide()', ->
  it 'divides numbers', ->
    assert.strictEqual new RObject(12).divide(new RObject(3)).value(), 4

describe '#mod()', ->
  it 'mods numbers', ->
    assert.strictEqual new RObject(11).mod(new RObject(2)).value(), 1

describe '#greaterThan()', ->
  it 'smaller number greaterThan bigger number is false', ->
    assert.strictEqual new RObject(4).greaterThan(new RObject(5)).value(), false

  it 'bigger number greaterThan smaller number is true', ->
    assert.strictEqual new RObject(6).greaterThan(new RObject(5)).value(), true

  it 'equal numbers greaterThan is false', ->
    assert.strictEqual new RObject(6).greaterThan(new RObject(6)).value(), false

describe '#greaterThanOrEqual()', ->
  it 'smaller number greaterThanOrEqual bigger number is false', ->
    assert.strictEqual new RObject(4).greaterThanOrEqual(new RObject(5)).value(), false

  it 'bigger number greaterThanOrEqual smaller number is true', ->
    assert.strictEqual new RObject(6).greaterThanOrEqual(new RObject(5)).value(), true

  it 'equal numbers greaterThanOrEqual is true', ->
    assert.strictEqual new RObject(6).greaterThanOrEqual(new RObject(6)).value(), true

describe '#lessThan()', ->
  it 'smaller number lessThan bigger number is true', ->
    assert.strictEqual new RObject(4).lessThan(new RObject(5)).value(), true

  it 'bigger number lessThan smaller number is false', ->
    assert.strictEqual new RObject(6).lessThan(new RObject(5)).value(), false

  it 'equal numbers lessThan is false', ->
    assert.strictEqual new RObject(6).lessThan(new RObject(6)).value(), false

describe '#lessThanOrEqual()', ->
  it 'smaller number lessThanOrEqual bigger number is true', ->
    assert.strictEqual new RObject(4).lessThanOrEqual(new RObject(5)).value(), true

  it 'bigger number lessThanOrEqual smaller number is false', ->
    assert.strictEqual new RObject(6).lessThanOrEqual(new RObject(5)).value(), false

  it 'equal numbers lessThanOrEqual is true', ->
    assert.strictEqual new RObject(6).lessThanOrEqual(new RObject(6)).value(), true

#todo: handle different types
describe '#is()', ->
  it 'same numbers give true', ->
    assert.strictEqual new RObject(6).is(new RObject(6)).value(), true

  it 'different numbers give false', ->
    assert.strictEqual new RObject(5).is(new RObject(6)).value(), false







# describe '#inverse()', ->
#   describe 'empty', ->
#     it 'should give empty for initial empty', ->
#       o = new RObject()
#       inverse = o.inverse()
#       assert.strictEqual inverse.value(), null

#     it 'should clear dynamically changing value to empty', ->
#       o = new RObject(true)
#       inverse = o.inverse()
#       o.set null
#       assert.strictEqual inverse.value(), null

#   #todo: should give null or self?
#   describe 'string', ->
#     it 'should give same value for initial string', ->
#       o = new RObject('asdf')
#       inverse = o.inverse()
#       assert.strictEqual inverse.value(), 'asdf'

#     it 'should give same value dynamically changing value to string', ->
#       o = new RObject(true)
#       inverse = o.inverse()
#       o.set 'asdf'
#       assert.strictEqual inverse.value(), 'asdf'

#   describe 'object', ->
#     it 'should give same value for initial object', ->
#       o = new RObject({a: 'aaa'})
#       inverse = o.inverse()
#       assert.strictEqual inverse.value().a, 'aaa'

#     it 'should give same value dynamically changing value to object', ->
#       o = new RObject(true)
#       inverse = o.inverse()
#       o.set {a: 'aaa'}
#       assert.strictEqual inverse.value().a, 'aaa'

#   describe 'array', ->
#     it 'should give same value for initial array', ->
#       o = new RObject([3])
#       inverse = o.inverse()
#       assert.strictEqual inverse.value()[0], 3

#     it 'should give same value dynamically changing value to array', ->
#       o = new RObject(true)
#       inverse = o.inverse()
#       o.set [3]
#       assert.strictEqual inverse.value()[0], 3

#   describe 'boolean', ->
#     it 'should inverse initial value', ->
#       o = new RObject(false)
#       inverse = o.inverse()
#       assert.strictEqual inverse.value(), true

#     it 'should inverse dynamically changing boolean', ->
#       o = new RObject(false)
#       inverse = o.inverse()
#       o.set true
#       assert.strictEqual inverse.value(), false

#     it 'should inverse dynamically changing boolean from other type', ->
#       o = new RObject()
#       inverse = o.inverse()
#       o.set true
#       assert.strictEqual inverse.value(), false

#   describe 'number', ->
#     it 'should inverse initial value', ->
#       o = new RObject(5)
#       inverse = o.inverse()
#       assert.strictEqual inverse.value(), -5

#     it 'should inverse dynamically changing number', ->
#       o = new RObject(6)
#       inverse = o.inverse()
#       o.set 7
#       assert.strictEqual inverse.value(), -7

#     it 'should inverse dynamically changing number from other type', ->
#       o = new RObject()
#       inverse = o.inverse()
#       o.set 3
#       assert.strictEqual inverse.value(), -3

#   describe 'proxy', ->
#     it 'should inverse a proxied number', ->
#       original = new RObject(7)
#       proxy = new RObject(original)
#       inverse = proxy.inverse()
#       assert.strictEqual inverse.value(), -7






#todo: edge case, called with empty and stuff
#todo: negative number indexes


#todo: rerun fn if an RObject wasnt returned?
# describe '#map()', ->
#   inverse = (item) ->
#     item.inverse()

#   #todo: test multi adds/removes

#   describe 'type: Array', ->
#     it 'should map initial items', ->
#       o = new RObject([1, 2])
#       inversed = o.map inverse
#       assert.deepEqual inversed.value(), [-1, -2]

#     it 'should map item added later', ->
#       o = new RObject([2])
#       inversed = o.map inverse
#       o.splice 0, 0, 1
#       assert.deepEqual inversed.value(), [-1, -2]

#     it 'should remove item from the child when item is removed from the parent', ->
#       o = new RObject([1, 2, 3])
#       inversed = o.map inverse
#       o.splice 1, 1
#       assert.deepEqual inversed.value(), [-1, -3]

#     it 'should set length of initial value', ->
#       o = new RObject([2])
#       inversed = o.map inverse
#       o.splice 0, 0, 1
#       assert.deepEqual inversed.length().value(), 2

#     it 'should set length of items added later', ->
#       o = new RObject([2])
#       inversed = o.map inverse
#       inversedLength = inversed.length()
#       o.splice 0, 0, 1
#       assert.deepEqual inversedLength.value(), 2

#     it 'should maintain order of added items', ->
#       o = new RObject([1, 3])
#       inversed = o.map inverse
#       o.splice 1, 0, 2
#       assert.deepEqual inversed.value(), [-1, -2, -3]

#     it 'should only call transform fn once when item is added', ->
#       o = new RObject([1])
#       transforms = 0
#       inversed = o.map (item) ->
#         transforms++
#         item.inverse()

#       transforms = 0
#       o.splice 1, 0, new RObject(2)
#       assert.strictEqual transforms, 1

#     it 'should update when parent value changes', ->
#       num = new RObject(1)
#       o = new RObject([num])
#       inversed = o.map inverse
#       num.set(2)
#       assert.deepEqual inversed.value(), [-2]

#     it 'should not rerun transform fn when parent value changes', ->
#       num = new RObject(1)
#       o = new RObject([num])
#       transforms = 0
#       inversed = o.map (item) ->
#         transforms++
#         item.inverse()

#       num.set(2)
#       assert.strictEqual transforms, 1


#     describe 'non-RObject returned from transform fn', ->
#       it 'should transform initial items', ->
#         o = new RObject([1, 2])
#         inversed = o.map (item) ->
#           -item.value()

#         assert.deepEqual inversed.value(), [-1, -2]

#       it 'should transform items added later', ->
#         o = new RObject([])
#         inversed = o.map (item) ->
#           -item.value()

#         o.splice 0, 0, 1, 2
#         assert.deepEqual inversed.value(), [-1, -2]

#       it 'should fire add event with RObject', ->
#         o = new RObject([])
#         inversed = o.map (item) ->
#           -item.value()

#         adds = []
#         inversed.on 'add', (items) ->
#           adds = items

#         o.splice 0, 0, 1, 2
#         assert.deepEqual adds.map((add) -> add.value()), [-1, -2]

#   describe 'type: Other', ->
#     it 'should return null', ->
#       o = new RObject()
#       inversed = o.map inverse

#       assert.deepEqual inversed.value(), null

#   #todo: dynamic changes to every type

#   # it 'should handle dynamic type change', ->
#   #   o = new RObject()
#   #   inversed = o.map (item) ->
#   #     item.inverse()

#   #   o.set [3]
#   #   assert.deepEqual inversed.value(), [-3]
#   #   o.set null
#   #   assert.deepEqual inversed.value(), null


#todo: refector to use 1 assert vvvvvvv
#todo: text truthiness and falsyness
# describe '#filter()', ->
#   isEven = (num) ->
#     num.mod(new RObject(2)).is(new RObject(0))

#   describe 'type: Array', ->
#     # all arrays tested tests should start with a fail and pass and
#     # should end with a pass and fail

#     it 'should call back with an RObject for initial items', ->
#       o = new RObject [3]
#       isRObject = false
#       evens = o.filter (val) ->
#         isRObject = val instanceof RObject
#         new RObject true
#       assert.strictEqual isRObject, true

#     it 'should call back with an RObject for dynamically added items', ->
#       o = new RObject []
#       isRObject = false
#       evens = o.filter (val) ->
#         isRObject = val instanceof RObject
#         new RObject true
#       o.splice 0, 0, 3
#       assert.strictEqual isRObject, true

#     it 'should filter initial items', ->
#       o = new RObject([1, 2, 3, 4, 5, 6, 7])
#       evens = o.filter isEven
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should filter items added at an index', ->
#       o = new RObject([1, 2, 5, 6, 7])
#       evens = o.filter isEven
#       o.splice 2, 0, 3, 4
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should filter items added at the beginning', ->
#       o = new RObject([3, 4, 5, 6, 7])
#       evens = o.filter isEven
#       o.splice 0, 0, 1, 2
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should filter items added at the end', ->
#       o = new RObject([1, 2, 3, 4, 5])
#       evens = o.filter isEven
#       o.splice 4, 0, 6, 7
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should filter added items when it starts as empty', ->
#       o = new RObject []
#       filtered = o.filter -> new RObject true
#       o.splice 0, 0, 1, 2, 3, 4, 5, 6, 7
#       assert.deepEqual filtered.value(), [1, 2, 3, 4, 5, 6, 7]

#     it 'should filter added items when a single passing value is added', ->
#       o = new RObject [1, 2, 3, 5, 6, 7]
#       evens = o.filter isEven
#       o.splice 2, 0, 4
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should filter added items when a single failing value is added', ->
#       o = new RObject [1, 2, 3, 4, 6, 7]
#       evens = o.filter isEven
#       o.splice 3, 0, 5
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should remove items that are removed from the source', ->
#       source = new RObject [1, 2, 3, 11, 12, 13, 4, 5, 6, 7]
#       evens = source.filter isEven
#       source.splice 3, 3
#       assert.deepEqual evens.value(), [2, 4, 6]

#     it 'should add initial items when pass/fail boolean changes to pass', ->
#       passes = new RObject false
#       o = new RObject [1, 2, 3]
#       filtered = o.filter -> passes
#       passes.set true
#       assert.deepEqual filtered.value(), [1, 2, 3]

#     it 'should remove initial items when pass/fail boolean changes to fail', ->
#       passes = new RObject true
#       o = new RObject [1, 2, 3]
#       filtered = o.filter -> passes
#       passes.set false
#       assert.deepEqual filtered.value(), []

#     it 'should add dynamically added items when pass/fail boolean changes to pass', ->
#       passes = new RObject false
#       o = new RObject []
#       filtered = o.filter -> passes
#       o.splice 0, 0, 1, 2, 3
#       passes.set true
#       assert.deepEqual filtered.value(), [1, 2, 3]

#     it 'should remove dynamically added items when pass/fail boolean changes to fail', ->
#       passes = new RObject true
#       o = new RObject []
#       filtered = o.filter -> passes
#       o.splice 0, 0, 1, 2, 3
#       passes.set false
#       assert.deepEqual filtered.value(), []


#     it 'should handle add after source has been shifted left', ->
#       item = new RObject 7
#       o = new RObject [1, 2, 5, 6, item, 9, 10]
#       evens = o.filter isEven
#       o.splice 2, 2
#       item.set 8
#       assert.deepEqual evens.value(), [2, 8, 10]

#     it 'should handle remove after source has been shifted left', ->
#       item = new RObject 8
#       o = new RObject [1, 2, 5, 6, item, 9, 10]
#       evens = o.filter isEven
#       o.splice 2, 2
#       item.set 7
#       assert.deepEqual evens.value(), [2, 10]

#     # it.only 'should handle add after source has been shifted right', ->
#     #   item = new RObject 7
#     #   o = new RObject [1, 2, item, 9, 10]
#     #   evens = o.filter isEven
#     #   o.splice 2, 0, 5, 6
#     #   console.log 'pre set', o.value(), evens.value()
#     #   item.set 8
#     #   console.log 'post set', o.value(), evens.value()
#     #   assert.deepEqual evens.value(), [2, 6, 8, 10]

#     it 'should handle remove after source has been shifted right', ->
#       item = new RObject 8
#       o = new RObject [1, 2, item, 9, 10]
#       evens = o.filter isEven
#       o.splice 2, 0, 5, 6
#       item.set 7
#       assert.deepEqual evens.value(), [2, 6, 10]

#     # it 'should handle item removed, then added then filter fail then filter pass', ->
#     #   o = new RObject [new RObject(8)]
#     #   passes = new RObject true
#     #   filtered = o.filter -> passes

#     #   o.splice 0, 1
#     #   o.splice 0, 0, new RObject(9)

#     #   console.log 'passes.set false'
#     #   passes.set false
#     #   console.log 'passes.set true'
#     #   passes.set true

#     #   # console.log 'filtered result', filtered.

#     #   assert.deepEqual filtered.value(), [9]


#     it 'should maintain order of filtered arrays', ->
#       o = new RObject([1, 2, 3, 4, 5, 6])
#       evens = o.filter isEven
#       o.at(3).set 11
#       o.at(3).set 4
#       assert.deepEqual evens.value(), [2, 4, 6]



#   it 'should handle dynamic type change', ->
#     o = new RObject()
#     evens = o.filter isEven
#     o.set [3, 4]
#     assert.deepEqual evens.value(), [4]
#     o.set null
#     assert.deepEqual evens.value(), null


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

# describe '#add()', ->
#   o1 = new RObject(5)
#   o2 = new RObject(6)
#   result = o1.add(o2)
#   assert.strictEqual result.value(), 11
#   o1.set 12
#   assert.strictEqual result.value(), 18, "it should update when first value is changed"
#   o2.set 33
#   assert.strictEqual result.value(), 45, "it should update when second value is changed"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"


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





# describe '#multiply()', ->
#   o1 = new RObject(5)
#   o2 = new RObject(6)
#   result = o1.multiply(o2)
#   assert.strictEqual result.value(), 30, "it should multiply the initial values"
#   o1.set 12
#   assert.strictEqual result.value(), 72, "it should update when first value is changed"
#   o2.set 33
#   assert.strictEqual result.value(), 396, "it should update when second value is changed"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"


# describe '#divide()', ->
#   o1 = new RObject(-12)
#   o2 = new RObject(6)
#   result = o1.divide(o2)
#   assert.strictEqual result.value(), -2, "it should divide the initial values"
#   o1.set 36
#   assert.strictEqual result.value(), 6, "it should update when first value is changed"
#   o2.set 3
#   assert.strictEqual result.value(), 12, "it should update when second value is changed"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"

#   it 'should be Infinity when dividing by 0', ->
#     result = new RObject(12).divide(new RObject(0))
#     assert.strictEqual result.value(), Infinity


# describe '#mod()', ->
#   o1 = new RObject(1046)
#   o2 = new RObject(100)
#   result = o1.mod(o2)
#   assert.strictEqual result.value(), 46, "it should mod the initial values"
#   o1.set 1073
#   assert.strictEqual result.value(), 73, "it should update when first value is changed"
#   o2.set 110
#   assert.strictEqual result.value(), 83, "it should update when second value is changed"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"


# describe '#greaterThan()', ->
#   o1 = new RObject(8)
#   o2 = new RObject(6)
#   result = o1.greaterThan(o2)
#   assert.strictEqual result.value(), true, "it should test the initial values"
#   o1.set 3
#   assert.strictEqual result.value(), false, "it should update when first value is changed"
#   o2.set -5
#   assert.strictEqual result.value(), true, "it should update when second value is changed"
#   o1.set -5
#   assert.strictEqual result.value(), false, "equal numbers should fail the test"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"


# describe '#greaterThanOrEqual()', ->
#   o1 = new RObject(8)
#   o2 = new RObject(6)
#   result = o1.greaterThanOrEqual(o2)
#   assert.strictEqual result.value(), true, "it should test the initial values"
#   o1.set 3
#   assert.strictEqual result.value(), false, "it should update when first value is changed"
#   o2.set -5
#   assert.strictEqual result.value(), true, "it should update when second value is changed"
#   o1.set -5
#   assert.strictEqual result.value(), true, "equal numbers should pass the test"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"


# describe '#lessThan()', ->
#   o1 = new RObject(8)
#   o2 = new RObject(6)
#   result = o1.lessThan(o2)
#   assert.strictEqual result.value(), false, "it should test the initial values"
#   o1.set 3
#   assert.strictEqual result.value(), true, "it should update when first value is changed"
#   o2.set -5
#   assert.strictEqual result.value(), false, "it should update when second value is changed"
#   o1.set -5
#   assert.strictEqual result.value(), false, "equal numbers should fail the test"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"


# describe '#lessThanOrEqual()', ->
#   o1 = new RObject(8)
#   o2 = new RObject(6)
#   result = o1.lessThanOrEqual(o2)
#   assert.strictEqual result.value(), false, "it should test the initial values"
#   o1.set 3
#   assert.strictEqual result.value(), true, "it should update when first value is changed"
#   o2.set -5
#   assert.strictEqual result.value(), false, "it should update when second value is changed"
#   o1.set -5
#   assert.strictEqual result.value(), true, "equal numbers should pass the test"
#   assert.strictEqual result instanceof RObject, true, "it should return an RObject"



#todo: array concat
# describe '#concat()', ->
#   it 'should concat the initial values', ->
#     o1 = new RObject('foo')
#     o2 = new RObject('bar')
#     assert.strictEqual o1.concat(o2).value(), 'foobar'

#   it 'should return an RObject', ->
#     o1 = new RObject('foo')
#     o2 = new RObject('bar')
#     assert.strictEqual o1.concat(o2) instanceof RObject, true

#   it 'should update concated value when either value changes', ->
#     o1 = new RObject('foo')
#     o2 = new RObject('')
#     result = o1.concat(o2)
#     o2.set 'bar'
#     assert.strictEqual result.value(), 'foobar'
#     o1.set 'baz'
#     assert.strictEqual result.value(), 'bazbar'

# describe '#indexOf()', ->
#   it 'should have initial index value', ->
#     o1 = new RObject('foobarbaz')
#     o2 = new RObject('bar')
#     assert.strictEqual o1.indexOf(o2).value(), 3

#   it 'should return an RObject', ->
#     o1 = new RObject('foobarbaz')
#     o2 = new RObject('bar')
#     assert.strictEqual o1.indexOf(o2) instanceof RObject, true

#   it 'should give -1 for not found', ->
#     o1 = new RObject('foobarbaz')
#     o2 = new RObject('zing')
#     assert.strictEqual o1.indexOf(o2).value(), -1

#   it 'should update index when either value changes', ->
#     o1 = new RObject('barbaz')
#     o2 = new RObject('bar')
#     result = o1.indexOf(o2)
#     o1.set 'foobarbaz'
#     assert.strictEqual result.value(), 3
#     o2.set 'arb'
#     assert.strictEqual result.value(), 4

#   describe 'array', ->

#     it 'should give -1 for an initial empty array', ->
#       o = new RObject []
#       assert.strictEqual o.indexOf(new RObject()).value(), -1
