
RType = require './RType'

class RBoolean extends RType
  constructor: ->
    super
    @_val = !!@_val # is there a better way to do this?

  inverse: (operand) ->
    @combine RBoolean, (aVal) ->
      !aVal

  is: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal == bVal

module.exports = RBoolean
