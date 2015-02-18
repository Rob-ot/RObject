# RObject


## Warning!

This is a prototype/proof of concept/work in progress. Don't use this for mission-crirical projects.


## What is RObject?

### Core

At its core, RObject is a wrapper around a JavaScript value. This allows us to do cool things (farther down this doc).

Just like jQuery is a wrapper around a dom element RObject is a wrapper around an Object, Array, Boolean, Number, String, or null.

`new RObject(12)`


To get back the JavaScript object use the `.value` method.

```javascript
var num = new RObject(12)
num.value() // 12
```


Object properties can be accessed with `.prop`.

```javascript
var obj = new RObject({foo: 'bar'})
obj.prop('foo').value() // 'bar'
```

Array elements can be accessed using `.at`.

```javascript
var arr = new RObject(['baz'])
arr.at(0).value() // 'baz'
```

Note how `.prop` and `.at` return instances of RObjects so chaining is possible.

### Changes

RObjects can be changed using `.set`.

```javascript
var num = new RObject(12)
num.set(129)
num.value() // 129
```

`.prop` and `.at` references can hang around and will be updated when the base object/array is updated

```javascript
var names = new RObject(['Jack', 'Neo', 'Bob'])
var keanu = names.at(1)
keanu.value() // Neo
names.set(['Jack', 'John Wick', 'Bob'])
keanu.value() // John Wick
```

Non existant object props and array elements return an empty RObject reference which is also updated when the base object/array is updated.

```javascript
var user = new RObject(null)
var userName = user.prop('name')
userName.value() // null
user.set({name: 'Keanu'})
userName.value() // Keanu
```

Change events are fired when the value of an RObject changes.

```javascript
var num = new RObject(null)
num.on('change', function() { console.log('It changed!') })
num.set(34) // fires change event: It changed!
```

Object props and array elements also fire change events when the underlying object changes.

```javascript
var user = new RObject(null)
var userName = user.prop('name')
userName.on('change', function() { console.log('Name updated!') })
user.set({name: 'Keanu'}) // fires change event: Name updated!
```

### Operations

Operations can be performed on an RObject.

```javascript
var num1 = new RObject(3)
var num2 = new RObject(5)
var total = num1.add(num2)
var product = num1.multiply(num2)
total.value() // 8
product.value() // 15
```

All values are updated when the base values change.

```javascript
var age = new RObject(20)
var canDrinkInUS = age.greaterThanOrEqual(21)
var underage = canDrinkInUS.inverse()
underage.value() // true
age.set(23)
underage.value() // false
```

Array methods work too.

```javascript
var users = new RObject()

var yearsExperience = users.reduce(function(total, user) {
  return total.add(user.prop('experience'))
}, new RObject(0))

var shortNamedUsers = users.filter(function(user) {
  return user.prop('name').length().lessThan(new RObject(4))
})

var shortNames = shortNamedUsers.map(function(user) {
  return user.prop('name')
})

users.set([
  {name: 'Bob', experience: 6},
  {name: 'Amanda', experience: 7},
  {name: 'Jim', experience: 4}
])

yearsExperience.value() // 17
shortNames.value() // [ 'Bob', 'Jim' ]
```

## Demo

There is a very ugly demo app here http://www.middlerob.com/robject-todo/


## Background

I've been working on this project on and off for a couple years. It was originally inspired by functional reactive programming but obviously has developed a JavaScript twist.

Webapps are becoming more and more dynamic, especially with the rise of real time data. Some JavaScript frameworks deal with all these changes by detecting what has changed between renders. Libraries like Backbone handle changes by monitoring data objects but Backbones implementation has some serious limitations like nested data.

This monitoring-data approach also has some sharp edges: lots of changes to data often result in thrashing the DOM which degrades webapp performance significantly, it's possible to get into deadlock conditions with circular event listeners, and lots of event listeners can end up using a significant amount of of memory.

Good idea or not I wanted to get RObject out there to share with the world. Know that it's pretty messy from lots of iteration and experimentation.

Thanks for checking it out!

PS: If you have any feedback or thoughts on this feel free to email me rob@middlerob.com or Tweet me @rob__ot
