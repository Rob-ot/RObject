
gulp = require 'gulp'

coffee = require 'gulp-coffee'
# uglify = require 'gulp-uglify'

paths =
  scripts: 'src/*.coffee'
  build: 'build'

gulp.task 'compile', ->
  gulp.src paths.scripts
    .pipe coffee()
    .pipe gulp.dest paths.build


gulp.task 'watch', ->
  gulp.watch paths.scripts, ['compile']

gulp.task 'default', ['compile', 'watch']


