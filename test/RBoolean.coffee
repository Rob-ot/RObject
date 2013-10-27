
assert = require 'assert'

{RBoolean} = require '../'

describe 'RBoolean', ->
  describe '#value()', ->
    it 'should give the native value of the value passed in', ->
      assert.strictEqual new RBoolean(true).value(), true

    it 'should update the value when it is changed', ->
      rs = new RBoolean(false)
      assert.strictEqual rs.value(), false
      rs.set true
      assert.strictEqual rs.value(), true

  describe '#inverse()', ->
    it 'should inverse value and maintain over change', ->
      rs = new RBoolean(false)
      inverse = rs.inverse()
      assert.strictEqual inverse.value(), true
      rs.set true
      assert.strictEqual inverse.value(), false
