
assert = require 'assert'

{RNumber, RBoolean} = require '../'

describe 'RNumber', ->
  describe '#value()', ->
    it 'should give the native value of the value passed in', ->
      assert.strictEqual new RNumber(3).value(), 3

    it 'should update the value when it is changed', ->
      rs = new RNumber(3)
      assert.strictEqual rs.value(), 3
      rs.set 4
      assert.strictEqual rs.value(), 4

  describe '#add()', ->
    rn1 = new RNumber(5)
    rn2 = new RNumber(6)
    result = rn1.add(rn2)
    assert.strictEqual result.value(), 11, "it should add the initial values"
    rn1.set 12
    assert.strictEqual result.value(), 18, "it should update when first value is changed"
    rn2.set 33
    assert.strictEqual result.value(), 45, "it should update when second value is changed"
    assert.equal result instanceof RNumber, true, "it should return an RNumber"


  describe '#subtract()', ->
    rn1 = new RNumber(5)
    rn2 = new RNumber(6)
    result = rn1.subtract(rn2)
    assert.strictEqual result.value(), -1, "it should subtract the initial values"
    rn1.set 12
    assert.strictEqual result.value(), 6, "it should update when first value is changed"
    rn2.set 33
    assert.strictEqual result.value(), -21, "it should update when second value is changed"
    assert.equal result instanceof RNumber, true, "it should return an RNumber"


  describe '#multiply()', ->
    rn1 = new RNumber(5)
    rn2 = new RNumber(6)
    result = rn1.multiply(rn2)
    assert.strictEqual result.value(), 30, "it should multiply the initial values"
    rn1.set 12
    assert.strictEqual result.value(), 72, "it should update when first value is changed"
    rn2.set 33
    assert.strictEqual result.value(), 396, "it should update when second value is changed"
    assert.equal result instanceof RNumber, true, "it should return an RNumber"


  describe '#divide()', ->
    rn1 = new RNumber(-12)
    rn2 = new RNumber(6)
    result = rn1.divide(rn2)
    assert.strictEqual result.value(), -2, "it should divide the initial values"
    rn1.set 36
    assert.strictEqual result.value(), 6, "it should update when first value is changed"
    rn2.set 3
    assert.strictEqual result.value(), 12, "it should update when second value is changed"
    assert.equal result instanceof RNumber, true, "it should return an RNumber"

    it 'should be Infinity when dividing by 0', ->
      result = new RNumber(12).divide(new RNumber(0))
      assert.equal result.value(), Infinity


  describe '#mod()', ->
    rn1 = new RNumber(1046)
    rn2 = new RNumber(100)
    result = rn1.mod(rn2)
    assert.strictEqual result.value(), 46, "it should mod the initial values"
    rn1.set 1073
    assert.strictEqual result.value(), 73, "it should update when first value is changed"
    rn2.set 110
    assert.strictEqual result.value(), 83, "it should update when second value is changed"
    assert.equal result instanceof RNumber, true, "it should return an RNumber"


  describe '#greaterThan()', ->
    rn1 = new RNumber(8)
    rn2 = new RNumber(6)
    result = rn1.greaterThan(rn2)
    assert.strictEqual result.value(), true, "it should test the initial values"
    rn1.set 3
    assert.strictEqual result.value(), false, "it should update when first value is changed"
    rn2.set -5
    assert.strictEqual result.value(), true, "it should update when second value is changed"
    rn1.set -5
    assert.strictEqual result.value(), false, "equal numbers should fail the test"
    assert.equal result instanceof RBoolean, true, "it should return an RNumber"


  describe '#greaterThanOrEqual()', ->
    rn1 = new RNumber(8)
    rn2 = new RNumber(6)
    result = rn1.greaterThanOrEqual(rn2)
    assert.strictEqual result.value(), true, "it should test the initial values"
    rn1.set 3
    assert.strictEqual result.value(), false, "it should update when first value is changed"
    rn2.set -5
    assert.strictEqual result.value(), true, "it should update when second value is changed"
    rn1.set -5
    assert.strictEqual result.value(), true, "equal numbers should pass the test"
    assert.equal result instanceof RBoolean, true, "it should return an RNumber"


  describe '#lessThan()', ->
    rn1 = new RNumber(8)
    rn2 = new RNumber(6)
    result = rn1.lessThan(rn2)
    assert.strictEqual result.value(), false, "it should test the initial values"
    rn1.set 3
    assert.strictEqual result.value(), true, "it should update when first value is changed"
    rn2.set -5
    assert.strictEqual result.value(), false, "it should update when second value is changed"
    rn1.set -5
    assert.strictEqual result.value(), false, "equal numbers should fail the test"
    assert.equal result instanceof RBoolean, true, "it should return an RNumber"


  describe '#lessThanOrEqual()', ->
    rn1 = new RNumber(8)
    rn2 = new RNumber(6)
    result = rn1.lessThanOrEqual(rn2)
    assert.strictEqual result.value(), false, "it should test the initial values"
    rn1.set 3
    assert.strictEqual result.value(), true, "it should update when first value is changed"
    rn2.set -5
    assert.strictEqual result.value(), false, "it should update when second value is changed"
    rn1.set -5
    assert.strictEqual result.value(), true, "equal numbers should pass the test"
    assert.equal result instanceof RBoolean, true, "it should return an RNumber"


  describe '#negate()', ->
    rn1 = new RNumber(5)
    result = rn1.negate()
    assert.strictEqual result.value(), -5, "it should negate the initial values"
    rn1.set 12
    assert.strictEqual result.value(), -12, "it should update when value is changed"
    assert.equal result instanceof RNumber, true, "it should return an RNumber"

