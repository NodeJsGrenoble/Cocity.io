Q = require("q")
_ = require("underscore")

remotes = {}

@include = ->

  @on "connection": ->
    cookie_string = @socket.handshake.headers.cookie
    return unless cookie_string
    if res = cookie_string.match(/connect\.sid=s%3A([^\.]+)\./)
      session_id = decodeURIComponent res[1]
      @socket.set "sid", session_id
      console.log "connection", @id, session_id
    ###
    @session (err,session) =>
      console.log @session, session
      #@session["ID"] = @id
    ###

  ### ROOM ###     

  @helper emit_to_room: (room, args...) ->
    @socket.broadcast.to(room).emit args...

  @helper get_master: (room, except_id) ->
    if @io.sockets.manager.rooms["/#{room}"]?.length
      master_id = @io.sockets.manager.rooms["/#{room}"][0] 
      if except_id is master_id
        master_id = @io.sockets.manager.rooms["/#{room}"][1]
    master_id 

  @helper get_room_users: (room, cb) ->
    Q.all(
      _(@io.sockets.manager.rooms["/#{room}"]).map (socket_id) =>
        deferred = new Q.defer()
        @io.sockets.sockets[socket_id].get "me", (err, user) ->
          deferred.resolve(user)
        deferred.promise
    ).done cb

  @on me: (who)->
    @socket.set "me", who, =>
      console.log "Done setting me"
      @ack?()

  # One2One for WebRTC Nego
  @on message: ->
    console.log "message from", @id, @data
    otherClient = @io.sockets.sockets[@data.to]
    return unless otherClient
    delete @data.to
    @data.from = @id
    otherClient.emit "message", @data

  @on join: ->
    console.log "join", @data, @id
    @socket.get "me", (err, me) =>
      @emit_to_room @data, "joined", 
        room: @data
        id: @id
        user: me

      @get_room_users @data, (users) =>
        @ack? users

        @join @data

        @emit "master", @get_master(@data)

  leave = ->
    console.log "leaving"#, @socket.manager
    rooms = @socket.manager.roomClients[@id]
    for name of rooms
      if name
        @broadcast_to name.slice(1), "left",
          room: name
          id: @id

        @broadcast_to name.slice(1), "master", @get_master(name.slice(1), @id)

  @on disconnect: leave
  @on leave: leave

  @on create: ->
    console.log "create", @data, @ack
    @data = uuid() unless @data
    if @io.sockets.clients(@data).length
      @ack? "taken" 
    else
      @join @data
      @ack? null, @data

  # Chat
  @on chat: ->
     @broadcast_to @data.channel, "chat", @data
