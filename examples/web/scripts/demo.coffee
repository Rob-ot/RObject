
define (require) ->
  RObject = require '../../../build/RObject'
  $ = require './jquery'

  $main = $ '#main'


  window.tasks = tasks = new RObject [
    { title: 'Get groceries', done: false, tags: ['bbq', 'aad'] }
    { title: 'Wash car', done: false, tags: [] }
    { title: 'Make less lists', done: false, tags: [] }
  ]

  window.filterValue = filterValue = new RObject('')


  window.doneTasks = doneTasks = tasks.filter (task) ->
    task.prop 'done'

  window.filteredDoneTasks = filteredDoneTasks = doneTasks.filter (task) ->
    task.prop('title').indexOf(filterValue).is(new RObject(-1)).inverse()

  window.notDoneTasks = notDoneTasks = tasks.filter (task) ->
    task.prop('done').inverse()

  filteredTasks = tasks.filter (task) ->
    task.prop('title').indexOf(filterValue).is(new RObject(-1)).inverse()

  $add = $ '<button>', html: 'Add'
  $add.click ->
    tasks.push new RObject { title: 'new task', done: false, tags: [] }

  $filterInput = $ '<input>'

  $filterInput.on 'keyup input', ->
    filterValue.set $filterInput.val()


  addTag = (tag) ->
    $el = $ '<span>', class: 'tag'
    $label = $ '<span>'
    $edit = $ '<button>', class: 'delete', html: 'X'

    editableArea $label, tag

    $el.append ' ', $label, $edit

    $el

  tagList = (tags) ->
    $el = $ '<nav>', class: 'tagList'
    $tags = $ '<div>', class: 'tagsContainer'
    # $addTag = $ '<button>', class: 'addTag', html: 'Add tag'

    $el.append $tags#, $addTag

    tagViews = tags.map addTag

    tagViews.subscribe (tag, {index}) ->
      $tag = tag.value()
      if index is 0
        $tags.prepend $tag
      else
        $tag.insertAfter $tags.children().eq(index - 1)

    tagViews.on 'remove', (views, {index}) ->
      for view in views
        $tags.children().eq(index).remove()

    # $addTag.click ->
    #   tags.add new RObject 'new tag'
      # tagViews.at(tagViews.length().subtract(new RObject(1))).value().select()

    $el

  editableArea = ($el, model) ->
    $el.attr 'contenteditable', true

    $el.keydown (e) ->
      if e.keyCode == 13
        e.preventDefault()
        $el.blur()

    $el.on 'keyup input', (e) ->
      model.set $el.text()

    model.watch (value) ->
      $el.text value if $el.text() != value


  addTask = (task) ->
    $el = $ '<article>', class: 'task'
    $done = $ '<input type="checkbox">'
    $label = $ '<span>'

    editableArea $label, task.prop('title')

    $done.on 'change', ->
      checked = $done.is ':checked'
      task.prop('done').set !!checked

    $tags = tagList task.prop('tags')

    $el.append $done, $label, $tags

    task.prop('done').watch (value) ->
      $done.attr 'checked', !!value

    $el

  taskList = (tasks, $parent) ->
    views = tasks.map addTask

    views.subscribe (task, {index}) ->
      $task = task.value()
      if index is 0
        $parent.prepend $task
      else
        $task.insertAfter $parent.children().eq(index - 1)

    views.on 'remove', (views, {index}) ->
      for view in views
        $parent.children().eq(index).remove()

  taskSection = (label, tasks) ->
    $el = $ '<section>', class: 'taskSection'

    $label = $ '<div>', html: label
    $total = $ '<span>'
    $bottom = $ '<div>'
    $tasks = $ '<section>'

    $label.append $total
    $el.append $label, $tasks, $bottom

    length = tasks.length()
    empty = tasks.length().is new RObject(0)

    chars = tasks.reduce (prev, curr) ->
      prev.add curr.prop('title').length()
    , new RObject(0)

    chars.watch (value) ->
      $bottom.text "(#{value})"

    length.watch (value) ->
      $total.text " (#{value})"

    empty.watch (value) ->
      $el.toggleClass 'empty', !!value

    taskList tasks, $tasks

    $el

  $main.append $add
  $main.append taskSection 'All', tasks
  $main.append taskSection 'To Do', notDoneTasks
  $main.append taskSection 'Done', doneTasks

  $main.append $filterInput
  $main.append taskSection 'Search', filteredTasks
