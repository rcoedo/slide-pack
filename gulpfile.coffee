gulp = require 'gulp'

fs           = require 'fs'
gutil        = require 'gulp-util'
del          = require 'del'
concat       = require 'gulp-concat'
coffee       = require 'gulp-coffee'
coffeelint   = require 'gulp-coffeelint'
browserify   = require 'browserify'
coffeeify    = require 'coffeeify'
watchify     = require 'watchify'
source       = require 'vinyl-source-stream'
sass         = require 'gulp-sass'
importCss    = require 'gulp-import-css'
autoprefixer = require 'gulp-autoprefixer'
uglify       = require 'gulp-uglify'
rename       = require 'gulp-rename'
minifyCss    = require 'gulp-minify-css'
livereload   = require 'gulp-livereload'
zip          = require 'gulp-zip'
insert       = require 'gulp-insert'

gulp.task 'lint', ->
  gulp.src 'src/*.coffee'
    .pipe coffeelint()
    .pipe coffeelint.reporter 'default'

gulp.task 'clean:styles', ->
  del 'dist/*.css',
    force: true

buildStyles = (file) ->
  gulp.src file
    .pipe sass
        onError: (e) -> console.log e
    .pipe importCss()
    .pipe autoprefixer("last 2 versions", "> 1%", "ie 10")
    .pipe gulp.dest 'dist'

gulp.task 'build:styles', ['clean:styles'], ->
  buildStyles 'styles/slide-pack.scss'

gulp.task 'build:styles:watch', ['build:styles'], ->
  gulp.watch ['styles/**/*.scss'], ['build:styles']

gulp.task 'reload', ->
  livereload.listen()
  gulp.watch('dist/**').on('change', livereload.changed)
  gulp.watch('doc/**').on('change', livereload.changed)

bundleIt = (watch = false) ->
  bundler = browserify
      # Required watchify args
      cache: {}, packageCache: {}, fullPaths: false,
      entries: ['./src/index.coffee'],
      extensions: ['.coffee'],
      debug: true,
      ignoreMissing: true
  bundler.transform 'coffeeify'

  if watch
    bundler = watchify bundler

  rebundle = ->
    bundler.bundle()
      .on('error', gutil.log.bind(gutil, 'Browserify error'))
      .pipe source 'slide-pack.js'
      .pipe gulp.dest 'dist'

  bundler.on 'update', rebundle
  rebundle()

gulp.task 'clean:js', ->
  del 'dist/*.js',
    force: true

gulp.task 'uglify', ['build'], ->
  gulp.src 'dist/*.js'
    .pipe rename suffix : '.min'
    .pipe uglify(preserveComments : 'some')
    .pipe gulp.dest 'dist'

gulp.task 'minifycss', ['build'], ->
  gulp.src 'dist/*.css'
    .pipe rename suffix : '.min'
    .pipe minifyCss()
    .pipe gulp.dest 'dist'

gulp.task 'copy:templates', ->
  gulp.src 'templates/*.html'
    .pipe gulp.dest 'dist'


gulp.task 'build:js', ['clean:js'], -> bundleIt()

gulp.task 'build:js:watch', ['clean:js'], -> bundleIt(true)

gulp.task 'minify', ['build', 'uglify', 'minifycss']

gulp.task 'build', ['build:js', 'build:styles']

gulp.task 'bundle', ['licensing', 'build', 'copy:templates'], ->
  gulp.src ['dist/*.js', 'dist/*.css', 'dist/*.html']
    .pipe(zip('slide-pack.zip'))
    .pipe(gulp.dest 'dist')

gulp.task 'licensing', ['minify'], ->
  license = fs.readFileSync('LICENSE.txt', encoding : 'utf8')

  gulp.src ['dist/*.js', 'dist/*.css']
    .pipe(insert.prepend( "/*!\n#{license}\n*/\n"))
    .pipe(gulp.dest 'dist')

gulp.task 'dist', ['bundle', 'minify']

gulp.task 'clean', ['clean:js', 'clean:styles']

gulp.task 'build:watch', ['build:js:watch', 'build:styles:watch', 'reload']

gulp.task 'default', ['build']
