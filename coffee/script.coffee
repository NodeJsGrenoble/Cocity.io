angular.module('components', []).
  directive('tabs', ->
    restrict: 'E'
    transclude: true
    scope: {}
    controller: ($scope, $element) ->
      panes = $scope.panes = []

      $scope.select = (pane) ->
        angular.forEach panes, (pane) ->
          pane.selected = false
        pane.selected = true

      @addPane = (pane) ->
        $scope.select(pane) if panes.length is 0
        panes.push(pane)
    template:'''
      <div class="tabs">
        <ul class="tab-bar">
          <li ng-repeat="pane in panes" class="tab-bar__tab">
            <a href="" class="tab-bar__link" ng-class="{'is-active':pane.selected}" ng-click="select(pane)">{{pane.title}}</a>
          </li>
        </ul>
        <div class="tab-content" ng-transclude></div>
      </div>
    '''
    replace: true
  ).
  directive('pane', ->
    require: '^tabs'
    restrict: 'E'
    transclude: true
    scope: { title: '@' }
    link: (scope, element, attrs, tabsCtrl) ->
      tabsCtrl.addPane(scope)
    template: '''
      <div class="tab-pane" ng-class="{'is-active': selected}" ng-transclude>
      </div>
    '''
    replace: true
  ).
  factory("hashchange", ($rootScope) ->
    last_hash = window.location.hash
    on: (cb) ->
      console.log "on hashchange"
      setInterval ->
        if last_hash isnt window.location.hash
          console.log "onHashChange", window.location.hash
          last_hash = window.location.hash
          $rootScope.$apply ->
            cb?(last_hash)
      , 100
  ).
  factory("socket", ($rootScope) ->
    socket = io.connect()
    console.log "connected?"
    on: (event, cb) ->
      socket.on event, (args...) ->
        $rootScope.$apply ->
          cb.apply socket, args
    emit: (event, data, ack) ->
      if typeof data is "function"
        ack = data
        data = ""

      socket.emit event, data, (args...) ->
        $rootScope.$apply ->
          ack?.apply socket, args
  ).
  controller('AppCtrl', ($scope, socket, hashchange) ->
    
    window.scope = $scope
    
    first_connection = true

    $scope.channels = []
    $scope.current_channels = []
    $scope.messages = []
    $scope.message = 
      content: "Enter your message here"

    $scope.me = 
      username: "Anon" + (Math.round(Math.random() * 90000) + 10000)
      avatar: ""
      userAgent: navigator.userAgent

    $scope.$watch "channels", (n,o) ->
      console.log "channels, n", n, "o", o
    , true

    $scope.sendMessage = ->
      console.log "Sending.Message", $scope.message.content
      socket.emit "post", 
        author: $scope.me.username
        content: $scope.message.content
        hashtags: $scope.current_channels

    add_or_update_channel = (room) ->
      unless update_channel_state room.name, room
        $scope.channels.push room

    add_or_not_message = (msg) ->
      unless _($scope.messages).find((message) -> message.id is msg.id)
        $scope.messages.push msg

    update_channel_state = (name, state) ->
      if chan = _($scope.channels).find((chan) -> chan.name is name)
        console.log "Found channel #{name}"
        for k, v of state
          console.log "Updating channel #{name}.#{k} = #{v}"
          chan[k] = v
      else
        console.log "Not found channel #{name}"


    socket.on "connect", ->

      $scope.$watch "current_channels", (new_arr ,old_arr) ->
        console.log "currents_channels", new_arr, old_arr
        # Trick to join on first init
        if new_arr is old_arr
          old_arr = []
        # Chan to Join
        _(new_arr).difference(old_arr).forEach (chan) ->
          console.log "Joining #{chan}"

          socket.emit "join", chan , (users) ->
            console.log "Joined #{chan}, Users", users.length
            add_or_update_channel 
              name: chan
              users: users.length
              joined: true

        console.log "leave",  _(old_arr).difference(new_arr)
        # Chan to Leave
        _(old_arr).difference(new_arr).forEach (chan) ->
          console.log "Leaving #{chan}"
          socket.emit "leave", chan
          update_channel_state chan, joined: false

      , true

      hashchange.on current_channel = (hash) ->
        console.log "new hash", (hash ? window.location.hash).split(/\#/)[1..-1]
        $scope.current_channels = (hash ? window.location.hash).split(/\#/)[1..-1]

      current_channel()

      # Reconnect on deco
      unless first_connection
        window.location.reload()
      first_connection = false
      # Who am I ?
      socket.emit "me", $scope.me, =>
        # List Rooms
        socket.emit "list_rooms", (rooms) ->
          console.log "list_rooms", rooms
          add_or_update_channel room for room in rooms

    socket.on "room_update", (room) ->
      console.log "room_update", room
      add_or_update_channel room

    socket.on "post", (post) ->
      console.log "post", post
      if (_(post.hashtags).intersection($scope.current_channels).length > 0) or 
        ($scope.current_channels.length is 0)
          add_or_not_message post

  )

initialize = () ->
  mapOptions = {
    center: new google.maps.LatLng(40.705578, -73.978004)
    zoom: 8
    mapTypeId: google.maps.MapTypeId.ROADMAP
  }
  map = new google.maps.Map( document.getElementById("map"), mapOptions)

  centerMap = (position) ->
    lat = position.coords.latitude
    lng = position.coords.longitude

    map.setCenter(new google.maps.LatLng(lat,lng))

  # Center if geoloc
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition(centerMap)

google.maps.event.addDomListener(window, 'load', initialize)
