module.exports = (grunt) ->

  # Project configuration
  grunt.initConfig(
    nodemon:
      dev:
        options:
          file: 'server.coffee'
    watch:
      sass:
        files: ['sass/**/*.scss']
        tasks: ['sass']
        options:
          nospawn: true
      jade:
        files: ['views/**/*.jade']
      triggerLiveReloadOnTheseFiles:
        # We use this target to watch files that will trigger the livereload
        options:
          livereload: true
        files: [
          # Anytime css is edited or compiled by sass, trigger the livereload on those files
          'public/css/*.css'
        ]
    sass:
      dist:
        options:
          outputStyle: 'nested'
        files:
          'public/css/main.css': 'sass/main.scss'
    concurrent:
      target:
        tasks: ['nodemon', 'watch']
        options:
          logConcurrentOutput: true
  )

  # Load the plugin that provides the "sass" task.
  grunt.loadNpmTasks('grunt-sass')

  # Load the plugin that provides the "watch" task.
  grunt.loadNpmTasks('grunt-contrib-watch')

  # Load the plugin that provides the "nodemon" task.
  grunt.loadNpmTasks('grunt-nodemon')

  # Load the plugin that provides the "concurrent" task.
  grunt.loadNpmTasks('grunt-concurrent')

  # Default task(s).
  grunt.registerTask('default', ['concurrent'])
