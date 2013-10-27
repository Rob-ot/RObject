
assert = require 'assert'

{RArray, RNumber} = require '../'


# make sure all methods work with multi-adds/removes
# make sure all methods handle when values change
# edge case, called with null and stuff


describe 'RArray', ->
  describe '#value()', ->
    it 'should give the native value of the value passed in', ->
      assert.deepEqual new RArray([]).value(), []

    it 'should default to an empty list', ->
      assert.deepEqual new RArray().value(), []

  describe '#add()', ->
    it 'should add item and trigger add event', ->
      ra = new RArray()
      one = new RNumber(1)
      addTriggered = false
      ra.on 'add', (item, {index}) ->
        assert.strictEqual item, one, 'add event should include added item'
        assert.strictEqual ra.length.value(), 1, 'array length should be updated by the time add event is triggered'
        assert.strictEqual index, 0, 'add event should include index'
        addTriggered = true

      ra.add one
      assert.equal addTriggered, true
      assert.deepEqual ra.value(), [one]

    it 'should add at the index if one is specified', ->
      ra = new RArray([new RNumber(5), new RNumber(6), new RNumber(7)])
      one = new RNumber(1)
      addTriggered = false
      ra.on 'add', (item, {index}) ->
        assert.strictEqual item, one, 'add event should include added item'
        assert.strictEqual ra.length.value(), 4, 'array length should be updated by the time add event is triggered'
        assert.strictEqual index, 2, 'add event should include index'
        addTriggered = true

      ra.add one, {at: 2}
      assert.equal addTriggered, true
      assert.deepEqual ra.toObject(), [5, 6, 1, 7]

    it 'should allow adding multiple items via Array', ->
      ra = new RArray([new RNumber(3), new RNumber(8), new RNumber(9)])
      addsTriggered = 0
      four = new RNumber(4)
      five = new RNumber(5)
      six = new RNumber(6)
      seven = new RNumber(7)
      ra.on 'add', (item, {index}) ->
        assert.deepEqual item, [four, five, six, seven], 'add event should include added items'
        assert.strictEqual ra.length.value(), 7, 'array length should be updated by the time add event is triggered'
        assert.strictEqual index, 1, 'add event should include index'
        addsTriggered++

      ra.add [four, five, six, seven], {at: 1}
      assert.deepEqual ra.toObject(), [3, 4, 5, 6, 7, 8, 9]
      assert.equal addsTriggered, 1



  describe '#splice()', ->
    nums = for i in [0..10]
      new RNumber i

    ra = new RArray()
    ra.splice 0, 0, nums[0], nums[1]
    assert.deepEqual ra.toObject(), [0, 1]

    it 'should add to beginning', ->
      addCalls = 0
      removeCalls = 0
      add = (items, {index}) ->
        assert.deepEqual items, nums[2]
        assert.strictEqual index, 0
        addCalls++
      remove = (items, {index}) ->
        removeCalls++

      ra.on 'add', add
      ra.on 'remove', remove

      ra.splice 0, 0, nums[2]
      assert.deepEqual ra.toObject(), [2, 0, 1]
      assert.equal addCalls, 1
      assert.equal removeCalls, 0

      ra.removeListener 'add', add
      ra.removeListener 'remove', remove

    it 'should add to end', ->
      addCalls = 0
      removeCalls = 0
      add = (items, {index}) ->
        assert.deepEqual items, nums[3]
        assert.strictEqual index, 3
        addCalls++
      remove = (items, {index}) ->
        removeCalls++

      ra.on 'add', add
      ra.on 'remove', remove

      ra.splice 3, 0, nums[3]
      assert.deepEqual ra.toObject(), [2, 0, 1, 3]
      assert.equal addCalls, 1
      assert.equal removeCalls, 0

      ra.removeListener 'add', add
      ra.removeListener 'remove', remove

    it 'should remove 1 at index', ->
      addCalls = 0
      removeCalls = 0
      add = (items, {index}) ->
        addCalls++
      remove = (items, {index}) ->
        assert.deepEqual items, nums[0]
        assert.strictEqual index, 1
        removeCalls++

      ra.on 'add', add
      ra.on 'remove', remove

      removed = ra.splice 1, 1
      assert.deepEqual ra.toObject(), [2, 1, 3]
      # assert.deepEqual removed, []
      assert.equal addCalls, 0
      assert.equal removeCalls, 1

      ra.removeListener 'add', add
      ra.removeListener 'remove', remove

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

      ra.on 'add', add
      ra.on 'remove', remove

      ra.splice 1, 1, nums[4], nums[5], nums[6], nums[7]
      assert.deepEqual ra.toObject(), [2, 4, 5, 6, 7, 3]
      assert.equal addCalls, 1
      assert.equal removeCalls, 1

      ra.removeListener 'add', add
      ra.removeListener 'remove', remove

    it 'should remove all', ->
      addCalls = 0
      removeCalls = 0
      add = (items, {index}) ->
        addCalls++
      remove = (items, {index}) ->
        assert.deepEqual items, [nums[2], nums[4], nums[5], nums[6], nums[7], nums[3]]
        assert.strictEqual index, 0
        removeCalls++

      ra.on 'add', add
      ra.on 'remove', remove

      ra.splice 0, 6
      assert.deepEqual ra.toObject(), []
      assert.equal addCalls, 0
      assert.equal removeCalls, 1

      ra.removeListener 'add', add
      ra.removeListener 'remove', remove



    # change events
    # negative number indexes
    # edge cases





  describe '#map()', ->
    it 'should map initial items', ->
      ra = new RArray([new RNumber(1), new RNumber(2)])
      negated = ra.map (item) ->
        item.negate()
      assert.deepEqual negated.value().map((i) -> i.value()), [-1, -2]

    it 'should map items added later', ->
      ra = new RArray([new RNumber(1)])
      negated = ra.map (item) ->
        item.negate()
      ra.add new RNumber(2)
      assert.deepEqual negated.value().map((i) -> i.value()), [-1, -2]

    it 'should only call transform fn once when item is added', ->
      ra = new RArray([new RNumber(1)])
      transforms = 0
      negated = ra.map (item) ->
        transforms++
        item.negate()

      transforms = 0
      ra.add new RNumber(2)
      assert.equal transforms, 1

    it 'should rerun transform fn when parent changes with intial value', ->
      num = new RNumber(1)
      ra = new RArray([num])
      negated = ra.map (item) ->
        item.negate()

      num.set(2)
      assert.deepEqual negated.toObject(), [-2]


  describe '#filter()', ->
    isEven = (num) ->
      num.mod(new RNumber(2)).is(new RNumber(0))

    it 'should filter initial items', ->
      ra = new RArray([new RNumber(4), new RNumber(5), new RNumber(6)])
      evens = ra.filter isEven
      assert.deepEqual evens.toObject(), [4, 6]

    it 'should filter added items', ->
      ra = new RArray([new RNumber(4), new RNumber(5), new RNumber(6)])
      evens = ra.filter isEven
      ra.add new RNumber(7)
      assert.deepEqual evens.toObject(), [4, 6]
      ra.add new RNumber(8)
      assert.deepEqual evens.toObject(), [4, 6, 8]

    it 'should filter added items when more than one is added at a time', ->
      ra = new RArray([new RNumber(4), new RNumber(5), new RNumber(6)])
      evens = ra.filter isEven
      ra.add [new RNumber(7), new RNumber(8)]
      assert.deepEqual evens.toObject(), [4, 6, 8]

    it 'should filter added items and put them in the correct place when spliced', ->
      ra = new RArray([new RNumber(1), new RNumber(2), new RNumber(4), new RNumber(3), new RNumber(3), new RNumber(5), new RNumber(9), new RNumber(12)])
      evens = ra.filter isEven
      ra.splice 5, 0, new RNumber(7), new RNumber(8), new RNumber(9), new RNumber(10)
      assert.deepEqual evens.toObject(), [2, 4, 8, 10, 12]

    it 'should filter added items and put them in the correct place when spliced at position 0', ->
      ra = new RArray([new RNumber(3), new RNumber(4)])
      evens = ra.filter isEven
      ra.splice 0, 0, new RNumber(2)
      assert.deepEqual evens.toObject(), [2, 4]




