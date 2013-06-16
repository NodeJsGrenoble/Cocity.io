require "colors"
global.Q = require("q")
global._ = require "underscore"
request = require "request"

fq = require "./config/fq.coffee"

channels = 

  cowork:
    messages: [
      {
        id: "e9577827-5ad5-4484-9eeb-9c3d76f6029e"
        post_data: 1371347132131
        author: "Evangenieur"
        content: "Cowork In Grenoble, Espace de Co-working : htt://co-work.fr"
        poi:
          name: "Cowork In Grenoble"
          address: "12 rue Servan, Grenoble"
          coord: [45.191259031049356, 5.73309227314969]
      }

    ]
    poi: [
      {
        name: "Cowork In Grenoble"
        address: "12 rue Servan, Grenoble"
        coord: [45.191259031049356, 5.73309227314969]
      }
      {
        name: "Col'Inn"
        coord: [45.19083759999999, 5.718740599999999]
      }
    ]

require("zappajs") 4500, ->

  @set "view engine": "jade"
  @use "static"
  @io.set "log level", 0

  @include "./lib/room_manager.coffee"

  view_extend =
    scripts: [
          "/zappa/Zappa-simple.js"
          "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js"
          "//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore-min.js"
          "/index.js"
          "https://ajax.googleapis.com/ajax/libs/angularjs/1.0.7/angular.min.js"
          "https://maps.googleapis.com/maps/api/js?key=AIzaSyALgyOJvkCbURI1QyHP_ahk4M5GfSDvNsg&sensor=false"
          "/js/angular-google-maps.js"
          "/js/script.js"
        ]

  @get "/_suggest_poi": ->
    request("https://api.foursquare.com/v2/venues/suggestcompletion?ll=#{@query.ll}&query=#{@query.search}&client_id=#{fq.client_id}&client_secret=#{fq.client_secret}&v=20130615&limit=10")
    .pipe @res

  @get "/_address2geo": ->
    request("http://maps.googleapis.com/maps/api/geocode/json?address=#{@query.address}&sensor=false")
    .pipe @res

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

      console.log
      @connect()

      first_connection = true
      ###
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
      ###


      @on joined: ->
        console.log "joined", @data

      @on left: ->
        console.log "left", @data

      @on room: ->
        console.log "room", @data

      @on "message": ->
       $("#room").append @data + "<br/>"
       console.log @data


#  @view "index": -
  @on connection: -> console.log "Connected".green
  # Rooms as middle war for dynamic routes
  @use (req, res, next) ->
    res.render "index", view_extend

