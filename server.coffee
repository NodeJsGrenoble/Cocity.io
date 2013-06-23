require "colors"
global.Q = require("q")
global._ = require "underscore"
request = require "request"

### Config ###
cocity = require "./config/cocity.coffee"
fq = require "./config/fq.coffee"


require("zappajs") 4500, ->

  @set "view engine": "jade"
  @use "static"
  @io.set "log level", 0

  @include "./lib/room_manager.coffee"

  # Extend with config and loading parameters
  view_extend = _(
    scripts: [
      "/js/conf.js"
      "/socket.io/socket.io.js"
      "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js"
      "//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore-min.js"
      "https://ajax.googleapis.com/ajax/libs/angularjs/1.1.5/angular.min.js"

      "https://maps.googleapis.com/maps/api/js?sensor=false"
      "/js/angular-google-maps.js"

      "//cdnjs.cloudflare.com/ajax/libs/jquery-timeago/1.1.0/jquery.timeago.min.js"
      "/js/localStorageModule.js"
      "/js/fastclick.js"
      "/js/script.js"
    ]    
  ).defaults cocity

  @get "/js/conf.js": ->
    @send """
      window.cocity = #{JSON.stringify cocity };
    """
  @get "/_suggest_poi": ->
    request("https://api.foursquare.com/v2/venues/suggestcompletion?" +
      "ll=#{@query.ll}&query=#{encodeURIComponent @query.search}&client_id=#{fq.client_id}&" +
      "client_secret=#{fq.client_secret}&v=20130615&limit=10")
    .pipe @res

  @get "/_address2geo": ->
    request("http://maps.googleapis.com/maps/api/geocode/json?address=#{@query.address}&sensor=false")
    .pipe @res

  @get "/": ->
    @render "index", view_extend


#  @view "index": -
  @on connection: -> console.log "Connected".green
  # Rooms as middle war for dynamic routes
  @use (req, res, next) ->
    res.render "index", view_extend

