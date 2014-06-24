
RObject = require '../src/RObject'

# todo: http library :P
http =
  get: (url) ->
    o = new RObject()

    # simulate an async http request
    setTimeout ->
      o.set {
        fName: 'Rob'
        lName: 'Middleton'
        age: 24
        favorites: [
          { type: 'show', id: 'sh-1' }
          { type: 'channel', id: 'ch-1' }
          { type: 'channel', id: 'ch-2' }
          { type: 'show', id: 'sh-2' }
          { type: 'team', id: 't-1' }
          { type: 'team', id: 't-2' }
          { type: 'show', id: 'sh-3' }
        ]
      }
    , 500

    return o


url = new RObject "/users/1"
user = http.get url
drinkingAge = new RObject(21)

canDrink = user.prop('age').greaterThanOrEqual drinkingAge
fullName = user.prop('fName').concat(new RObject(' ')).concat(user.prop('lName'))
favoriteShows = user.prop('favorites').filter (fav) ->
  ret = fav.prop('type').is(new RObject('show'))
  ret.watch (v) -> console.log("aaa", fav.prop('type'), ret.value())
  ret



console.log 'now', canDrink.value(), fullName.value(), favoriteShows.value()


setTimeout ->
  console.log 'later', canDrink.value(), fullName.value(), favoriteShows.value()
, 1000
