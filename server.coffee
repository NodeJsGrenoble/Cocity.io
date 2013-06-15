require "colors"

require("zappajs") 4500, ->

  @set "view engine": "jade"

  @get "/": ->
    @render "index"
 
  @client "/index.js": ->
    $ =>
      $("#txt").keyup (e) =>
        if e.keyCode is 13
          @emit "message", $("#txt").val()
          $("#txt").val("")
      @connect()
      @on "message": ->
       console.log "receiving ", @data
       $("#room").append @data + "<br/>"
    

#  @view "index": -
  @on connection: -> console.log "Connected".green
  @on message: ->
    console.log "new message".rainbow, @data
    @broadcast "message", @data
    @emit "message", @data
