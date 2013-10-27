
assert = require 'assert'

{RString, RNumber} = require '../'

describe 'RString', ->
  describe '#value()', ->
    it 'should give the native value of the value passed in', ->
      assert.strictEqual new RString('foo').value(), 'foo'

    it 'should update the value when it is changed', ->
      rs = new RString('foo')
      assert.strictEqual rs.value(), 'foo'
      rs.set 'bar'
      assert.strictEqual rs.value(), 'bar'

  describe '#concat()', ->
    it 'should concat the initial values', ->
      rs1 = new RString('foo')
      rs2 = new RString('bar')
      assert.strictEqual rs1.concat(rs2).value(), 'foobar'

    it 'should return an RString', ->
      rs1 = new RString('foo')
      rs2 = new RString('bar')
      assert.equal rs1.concat(rs2) instanceof RString, true

    it 'should update concated value when either value changes', ->
      rs1 = new RString('foo')
      rs2 = new RString()
      result = rs1.concat(rs2)
      rs2.set 'bar'
      assert.strictEqual result.value(), 'foobar'
      rs1.set 'baz'
      assert.strictEqual result.value(), 'bazbar'

  describe '#indexOf()', ->
    it 'should have initial index value', ->
      rs1 = new RString('foobarbaz')
      rs2 = new RString('bar')
      assert.strictEqual rs1.indexOf(rs2).value(), 3

    it 'should return an RNumber', ->
      rs1 = new RString('foobarbaz')
      rs2 = new RString('bar')
      assert.equal rs1.indexOf(rs2) instanceof RNumber, true

    it 'should give -1 for not found', ->
      rs1 = new RString('foobarbaz')
      rs2 = new RString('zing')
      assert.strictEqual rs1.indexOf(rs2).value(), -1

    it 'should update index when either value changes', ->
      rs1 = new RString('barbaz')
      rs2 = new RString('bar')
      result = rs1.indexOf(rs2)
      rs1.set 'foobarbaz'
      assert.strictEqual result.value(), 3
      rs2.set 'arb'
      assert.strictEqual result.value(), 4


