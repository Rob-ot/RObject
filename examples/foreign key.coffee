RObject = require '../src/RObject'

users = new RObject [
  { id: 'a', name: 'Rob' }
  { id: 'b', name: 'Bob' }
  { id: 'c', name: 'Jack' }
  { id: 'd', name: 'Jill' }
]

blogs = new RObject [
  { title: 'How to a', creatorId: 'a' }
  { title: 'How to c', creatorId: 'c' }
  { title: 'How to b', creatorId: 'b' }
]

usersById = users.indexBy('id')
richBlogs = blogs.map (blog) ->
  blog.extend { creator: usersById.prop(blog.prop('creatorId')) }


richBlogs.at(1).prop('creator').prop('name') # == Jack

blogs.at(1).prop('creatorId').set('d')
richBlogs.at(1).prop('creator').prop('name') # == Jill

usersById.prop('d').prop('name').set('Leroy')
richBlogs.at(1).prop('creator').prop('name') # == Leroy

blogs.push { title: 'One weird trick', creatorId: 'e' }
richBlogs.at(3).prop('creator').prop('name') # == null

usersById.push { id: 'e', name: 'ZZ-top' }
richBlogs.at(3).prop('creator').prop('name') # == ZZ-top




# users = new RObject {
#   a: { name: 'Rob' }
#   b: { name: 'Bob' }
#   c: { name: 'Jack' }
#   d: { name: 'Jill' }
# }

# blogs = new RObject [
#   { title: 'How to a', creatorId: 'a' }
#   { title: 'How to c', creatorId: 'c' }
#   { title: 'How to b', creatorId: 'b' }
# ]

# richBlogs = blogs.map (blog) ->
#   new RObject {
#     title: blog.prop('title')
#     creator: users.prop(blog.prop('creatorId'))
#   }


# console.log richBlogs.at(1).prop('creator').prop('name').value()

# blogs.at(1).prop('creatorId').set('d')
# console.log richBlogs.at(1).prop('creator').prop('name').value()

# users.prop('d').prop('name').set('Leroy')
# console.log richBlogs.at(1).prop('creator').prop('name').value()

# blogs.push { title: 'One weird trick', creatorId: 'e' }
# console.log richBlogs.at(3).prop('creator').prop('name').value()

# users.prop('e').set { name: 'Babeque' }
# console.log richBlogs.at(3).prop('creator').prop('name').value()
