
RType = require './RType'
RNumber = require './RNumber'
RBoolean = require './RBoolean'

class RString extends RType

  concat: (operand) ->
    @combine RString, operand, (aVal, bVal) ->
      aVal + bVal

  indexOf: (operand) ->
    @combine RNumber, operand, (aVal, bVal) ->
      aVal.indexOf bVal

  is: (operand) ->
    @combine RBoolean, operand, (aVal, bVal) ->
      aVal == bVal

module.exports = RString
