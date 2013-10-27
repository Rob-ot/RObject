
assert = require 'assert'

{RType, RString, RNumber, RBoolean, RArray} = require '../'

describe 'RType', ->
  describe '#toObject()', ->
    it 'should give native value for simple types', ->
      assert.strictEqual new RString('foo').toObject(), 'foo'
      assert.strictEqual new RNumber(6).toObject(), 6
      assert.strictEqual new RBoolean(true).toObject(), true

    it 'should give native value for arrays and their contents', ->
      complex = new RArray([
        new RString('foo')
        new RNumber(6)
        new RBoolean(true)
        new RArray([new RNumber(3)])
      ])
      assert.deepEqual complex.toObject(), ['foo', 6, true, [3]]


  #todo move to individual type files and use this for cross-type checks only
  describe '#is()', ->
    rn1 = new RNumber(4)
    rn2 = new RNumber(4)
    result = rn1.is(rn2)
    assert.strictEqual result.value(), true, 'it should test the initial values'
    rn1.set 5
    assert.strictEqual result.value(), false, 'it should update when first value is changed'
    rn2.set 5
    assert.strictEqual result.value(), true, 'it should update when second value is changed'
    rn2.set '5'
    assert.strictEqual result.value(), false, 'it should not equal across types'
    assert.equal result instanceof RBoolean, true, 'it should return an RBoolean'
