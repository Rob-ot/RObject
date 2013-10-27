
RType = require './RType'
RBoolean = require './RBoolean'

class RNumber extends RType
  constructor: ->
    super
    @_val = +@_val # is there a better way to do this?

  add: (operand) ->
    @combine RNumber, operand, (aVal, bVal) ->
      aVal + bVal

  subtract: (operand) ->
    @combine RNumber, operand, (aVal, bVal) ->
      aVal - bVal

  multiply: (operand) ->
    @combine RNumber, operand, (aVal, bVal) ->
      aVal * bVal

  divide: (operand) ->
    @combine RNumber, operand, (aVal, bVal) ->
      aVal / bVal

  mod: (operand) ->
    @combine RNumber, operand, (aVal, bVal) ->
      aVal % bVal

  greaterThan: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal > bVal

  greaterThanOrEqual: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal >= bVal

  lessThan: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal < bVal

  lessThanOrEqual: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal <= bVal

  is: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal == bVal

  negate: ->
    @combine RNumber, (val) ->
      -val


module.exports = RNumber
