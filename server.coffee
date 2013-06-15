require "colors"

require("zappajs") ->
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
    

  @view "index": ->
    html ->
      head ->
        script src:"/zappa/Zappa-simple.js"
        script src:"//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.2/jquery.min.js"
        script src:"/index.js"
      body ->
        h1 "Test #{if @home then "La Home" else "Pas la home"}"
        div "#room", ""
        input "#txt", type:"text"
      toto ->
        "test"

  
  @on connection: -> console.log "Connected".green
  @on message: ->
    console.log "new message".rainbow, @data
    @broadcast "message", @data
    @emit "message", @data
