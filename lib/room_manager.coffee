uuid = require "uuid"
util = require "util"

rooms_messages = require "../data/mock.coffee"

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

  @helper get_room_users: (room, cb) ->
    console.log "Num users for #{room}", @io.sockets.manager.rooms["/#{room}"]?.length
    if @io.sockets.manager.rooms["/#{room}"]?
      Q.all(
        _(@io.sockets.manager.rooms["/#{room}"]).map (socket_id) =>
          deferred = new Q.defer()
          @io.sockets.sockets[socket_id].get "me", (err, user) ->
            deferred.resolve(user)
          deferred.promise
      ).done cb
    else 
      cb []

  @on list_rooms: ->
    channels = _(
      _(@io.sockets.manager.rooms).chain().keys().map((route) -> route.slice 1).value().concat \
        _(rooms_messages).keys()
    ).uniq()
    console.log "channels", _(@io.sockets.manager.rooms).chain().keys().map((route) -> route.slice 1).value().concat \
        _(rooms_messages).keys()

    @ack? chans = _(channels).map (channel) => 
      name: channel or "Grenoble"
      users: @io.sockets.manager.rooms["/#{channel}"]?.length ? 0
      messages: rooms_messages[channel] ? []
    console.log "List rooms", util.inspect(@io.sockets.manager.rooms, colors: on)
    console.log "List chans", util.inspect(chans, colors: on)

  @on me: (who)->
    @socket.set "me", who, =>
      console.log "Done setting me"
      @ack?()

  
  @on post: ->
    _(@data.hashtags.concat [""]).each (hashtag) =>
      console.log "Sending Post to #{hashtag}"
      @broadcast_to hashtag, "post",
        _(@data).defaults
          id: uuid.v4()


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
        @ack? \
          users: users
          messages: rooms_messages[@data]

        @join @data

        @broadcast_to "", "room_update",
          name: @data
          users: users.length + 1

        console.log util.inspect(@io.sockets.manager.rooms, colors: on)



  leave = ->
    console.log "leaving", @data
    rooms = @socket.manager.roomClients[@id]
    for name of rooms
      if name.slice(1) is @data
        @broadcast_to name.slice(1), "left",
          room: name
          id: @id

        @leave name.slice(1)

        @get_room_users name.slice(1), (users) =>
          @broadcast_to "", "room_update",
            name: @data
            users: users.length

          console.log util.inspect(@io.sockets.manager.rooms, colors: on)


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
