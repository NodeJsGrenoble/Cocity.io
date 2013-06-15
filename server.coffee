require "colors"

require("zappajs") 4500, ->

  @set "view engine": "jade"
  @use "static"

  @get "/": ->
    @render "index", scripts: [
          "/zappa/Zappa-simple.js",
          "//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js",
          "/index.js"
        ]

  @client "/index.js": ->
    $ =>
      $("#txt").keyup (e) =>
        if e.keyCode is 13
          @emit "message", $("#txt").val()
          $("#txt").val("")
      @connect()
      @on "message": ->
       $("#room").append @data + "<br/>"


#  @view "index": -
  @on connection: -> console.log "Connected".green
  @on message: ->
    console.log "new message".rainbow, @data
    @broadcast "message", @data
    @emit "message", @data
