uuid = require "uuid"
util = require "util"
fs = require "fs"

rooms_messages = {} #JSON.parse(fs.readFileSync "./data/rooms.json")
#rooms_messages = require "../data/mock.coffee"

@include = ->

  @store = rooms_messages

  @on connection: ->
    @broadcast "total_connected", @io.sockets.manager.rooms[""].length
    @emit "total_connected", @io.sockets.manager.rooms[""].length

    ###
    cookie_string = @socket.handshake.headers.cookie
    return unless cookie_string
    if res = cookie_string.match(/connect\.sid=s%3A([^\.]+)\./)
      session_id = decodeURIComponent res[1]
      @socket.set "sid", session_id
      console.log "connection", @id, session_id

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
          @io.sockets.sockets[socket_id]?.get "me", (err, user) ->
            deferred.resolve(user)
          deferred.promise
      ).done cb
    else
      cb []

  @helper chan_infos: chan_infos = (channel) =>
    name: channel
    stats:
      users: @io.sockets.manager.rooms["/#{channel}"]?.length ? 0
      messages: rooms_messages[channel] ? []
      pois: _(rooms_messages[channel]).filter((msg) -> msg.poi?.name).length

  @helper send_post: @send_post = send_post = (data) ->
    _(data.hashtags.concat [""]).each (hashtag) =>
      msg = _(data).defaults
        id: uuid.v4()
        post_date: (new Date()).getTime()
      console.log "Sending Post to #{hashtag}"
      if hashtag
        unless rooms_messages[hashtag]
          rooms_messages[hashtag] = []

        #if msg.poi ? for persistency in cache ?
        rooms_messages[hashtag].push msg
        @io.sockets.in("").emit "room_update", chan_infos hashtag

        @io.sockets.in(hashtag).emit "post", msg

  console.log "@send_post?f", send_post?

  @on list_rooms: ->
    channels = _(
      _(@io.sockets.manager.rooms).chain().keys().map((route) -> route.slice 1).value().concat \
        _(rooms_messages).keys()
    ).uniq()
    console.log "channels", _(@io.sockets.manager.rooms).chain().keys().map((route) -> route.slice 1).value().concat \
        _(rooms_messages).keys()

    @ack? chans = _(channels).map @chan_infos
    console.log "List rooms", util.inspect(@io.sockets.manager.rooms, colors: on)
    console.log "List chans", util.inspect(chans, colors: on)

  @on me: (who)->
    @socket.set "me", who, =>
      console.log "Done setting me", who
      @ack?()


  @on get_posts: ->
    @ack? _(rooms_messages).chain().values().flatten().value()

  @on post: ->
    @send_post @data


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
        console.log "Messages for room #{@data}", rooms_messages[@data]
        @ack?(
          name: @data
          users: users
          messages: rooms_messages[@data]
        )

        @join @data

        @broadcast_to "", "room_update", @chan_infos @data

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
          @broadcast_to "", "room_update", @chan_infos @data

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

process.on "exit", ->
  console.log "Exited"
  #fs.writeFileSync "./data/rooms.json", JSON.stringify(rooms_messages, null, 4)
