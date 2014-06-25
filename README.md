


Values are almost never mutated, if you need to say reverse an array you would make a reversed (shallow) clone instead of reversing the original. Then, any time the original is modified the reversed clone will stay up to date as the current reversed version.

Sub-properties and array items are vivified to RObjects lazily and only as needed, therefore cyclical structures are supported.

Events should only be fired once object has been fully modified to its new state, events should not be fired with the state partially modified.


# v1

array push, pop, shift, unshift (append prepend?)

all/most standard js array operations



# ToDo

a nice api for grouping events, like .pauseEvents() and later resume to fire the least amount of events needed to get up to date. (coalescence)

A Date library that fires change events when time changes and stuff (simply wrap Moment)


_.span

2d arrays?

groupMap, just like map except gives arrays when new things are added in chunks, like for mapping favorites to add info by doing an xhr for each item )each group of items as they are added

error and empty types?

error type has code and message

when doing a number computation on a string, try converting it to a number?



do we need to do event bubbling? can we?
at least prop > object?

first class functions ?!?!

what happens when you create an RObject with an RObject?

make it more clear when the fn is a mutator ($ prefix maybe?)

o = new RObject({a: new RObject('a')})
o.prop('a', new RObject('b')) # what happens?!!


don't use at, use index

#default() (sets to given value if source is empty)

map returns an array of RObjects always, is that what we want? (query objects)

solved problems
types can change but everyone else already has a reference to an object so it can't change, must combine all types into same object

defer some computations to nextTick by passing in defer: true?

handle when set is called during a change event

toNumber, etc?

async map
throttle
groupMap

getters/virtuals

an easy way to track what instance you're looking at in js debugger, maybe give each instance a name and that name is added on to as it passes through monads

merge

merge array values when set to a new array?
