
{EventEmitter} = require 'events'
_ = require 'lodash'

class RType extends EventEmitter
  constructor: (@_val) ->

  value: -> @_val

  set: (val) ->
    @_val = val
    @emit "change"

  combine: (Type, operands..., handler) ->
    child = new Type()
    cb = =>
      operandValues = (operand.value() for operand in operands)
      child.set handler this.value(), operandValues...
    this.on "change", cb
    for operand in operands
      operand.on "change", cb
    cb()
    return child

  toObject: ->
    # this will be overridden in some children
    @value()

module.exports = RType
