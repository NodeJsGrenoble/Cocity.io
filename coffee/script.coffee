$ ->
  navigation = responsiveNav("#nav", {
    label: "list"
    openPos: "static"
  })

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

    first_connection = true

    $scope.channels = []
    $scope.current_channels = []

    $scope.$watch "channels", (n,o) ->
      console.log "channels, n", n, "o", o
    , true

    add_or_update_channel = (room) ->
      if chan = _($scope.channels).find((chan) -> chan.name is room.name)
        chan.users = room.users
      else
        $scope.channels.push room

    update_channel_state = (name, state) ->
      if chan = _($scope.channels).find((chan) -> chan.name is name)
        for k, v of state
          chan[k] = v


    socket.on "connect", ->

      $scope.$watch "current_channels", (new_arr ,old_arr) ->
        console.log "currents_channels", new_arr, old_arr
        # Trick to join on first init
        if new_arr is old_arr
          old_arr = []
        # Chan to Join 
        for chan in _(new_arr).difference(old_arr)
          console.log "Joining #{chan}"

          socket.emit "join", chan , (users) ->
            console.log "Users in #{chan}", users.length
            update_channel_state chan, joined: true

        console.log "leave",  _(old_arr).difference(new_arr)
        # Chan to Leave  
        for chan in _(old_arr).difference(new_arr)
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
      socket.emit "me",
        username: "Anon" + (Math.round(Math.random() * 90000) + 10000)
        avatar: ""
        userAgent: navigator.userAgent
        =>

          # List Rooms
          socket.emit "list_rooms", (rooms) ->
            console.log "list_rooms", rooms
            add_or_update_channel room for room in rooms

    socket.on "room_update", (room) ->
      console.log "room_update", room
      add_or_update_channel room

  )
