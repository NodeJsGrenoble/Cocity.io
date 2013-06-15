require "colors"
global.Q = require("q")
global._ = require "underscore"

require("zappajs") 4500, ->

  @set "view engine": "jade"
  @use "static"
  @io.set "log level", 0

  @include "./lib/room_manager.coffee"

  view_extend =
    scripts: [
          "/zappa/Zappa-simple.js",
          "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js",
          "/index.js",
          "/js/responsive-nav.min.js",
          "https://ajax.googleapis.com/ajax/libs/angularjs/1.0.7/angular.min.js",
          "/js/script.js"
        ]

  @get "/": ->
    @render "index", view_extend

  @client "/index.js": ->
    $ =>
      navigator.geolocation?.getCurrentPosition (pos)->
        console.log "postition", pos
      hashtags = location.href.split(/\//)[3..-1]

      $("#txt").keyup (e) =>
        if e.keyCode is 13
          @emit "message", $("#txt").val()
          $("#txt").val("")

      @connect()

      first_connection = true
      @on connect: =>
        window.location.reload() unless first_connection
        first_connection = false
        console.log "Connected"

        
        console.log "emit, me"
        @emit "me", 
          username: "Anon" + (Math.round(Math.random() * 90000) + 10000)
          avatar: "/img/anon_user.jpg"
          userAgent: navigator.userAgent
          =>
            # List Rooms
            @emit "list_rooms", "", (rooms) ->
              console.log "list_rooms", rooms

            # Join room for each hashtag

            hashtags.forEach (hashtag) =>
              console.log "Joining #{hashtag}"
              @emit "join", hashtag , (users) ->
                console.log "Users in #{hashtag}", users.length


      @on joined: ->
        console.log "joined", @data

      @on left: ->
        console.log "left", @data

      @on room: ->
        console.log "room", @data

      @on room_update: ->
        console.log "room_update", @data.room, @data.users.num

      @on "message": ->
       $("#room").append @data + "<br/>"
       console.log @data


#  @view "index": -
  @on connection: -> console.log "Connected".green
  # Rooms as middle war for dynamic routes
  @use (req, res, next) ->
    res.render "index", view_extend
  
