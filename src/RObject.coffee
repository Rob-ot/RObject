
RType = require './RType'

class RObject extends RType
  constructor: ->
    super
    @_val # it is assumed that all properties of passed in object are RTypes (for now)

module.exports = RObject
