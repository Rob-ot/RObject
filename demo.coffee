
RObject = require './src/RObject'
# someday allow non r chars and assume they never change

fName = new RObject("Rob")
lName = new RObject("Middleton")
fullName = fName.concat(lName)

index = fullName.indexOf new RObject("er")
indexPlusFive = index.add(new RObject(5))
indexGreaterThanSeven = index.greaterThan(new RObject(7))

console.log fullName.value(), index.value(), indexPlusFive.value(), indexGreaterThanSeven.value()
# RobMiddleton -1 4 false

fName.set("Robot")
console.log fullName.value(), index.value(), indexPlusFive.value(), indexGreaterThanSeven.value()
# RobotMiddleton -1 4 false

lName.set("Bender")
console.log fullName.value(), index.value(), indexPlusFive.value(), indexGreaterThanSeven.value()
# RobotBender 9 14 true

arr = new RObject([new RObject(30)])
negated = arr.map (num) ->
  num.inverse()

console.log negated.value()
# [ -30 ]

arr.add new RObject(25)
console.log negated.value()
# [ -30, -25 ]

