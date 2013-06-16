### Fastclick for responsive mobile click ###
window.addEventListener "load", (->
  FastClick.attach document.body
), false

### String HTTP Linker ###

autoLink = (options..., scope) ->
  pattern = ///
    (^|\s) # Capture the beginning of string or leading whitespace
    (
      (?:https?|ftp):// # Look for a valid URL protocol (non-captured)
      [\-A-Z0-9+\u0026@#/%?=~_|!:,.;]* # Valid URL characters (any number of times)
      [\-A-Z0-9+\u0026@#/%=~_|] # String must end in a valid URL character
    )
  ///gi

  return @replace(pattern, "$1<a href='$2'>$2</a>") unless options.length > 0

  option = options[0]
  linkAttributes = (
    " #{k}='#{v}'" for k, v of option when k isnt 'callback'
  ).join('')

  @replace pattern, (match, space, url) ->
    # First check if the url is not a video/image with embedly
    embedlyKey = "ad06c0ad1988423bb73edd6763020a90"

    embedlyCall = "http://api.embed.ly/1/oembed?key=#{embedlyKey}&url=#{url}&maxwidth=500"

    $.ajax(embedlyCall).
      done((data) ->
        if data.type is "photo"
          scope.message.rich = "<img src='#{data.url}'/>"
      )

    link = option.callback?(url) or
      "<a href='#{url}'#{linkAttributes}>#{url}</a>"

    "#{space}#{link}"

String::autoLink = autoLink


### Angular App ###

angular.module('cocity', ["google-maps"]).
  directive('tabs', ->
    restrict: 'E'
    transclude: true
    scope: {paneChanged: '&'}
    controller: ($scope, $element) ->
      panes = $scope.panes = []

      $scope.select = (pane) ->
        angular.forEach panes, (pane) ->
          pane.selected = false
        pane.selected = true
        $scope.paneChanged selectedPane: pane

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
  filter("matchCurrentChannels", ->
    (messages, current_channels) ->
      console.log "Filtering", messages, current_channels, arguments
      if current_channels?.length
        _(messages).filter (msg) ->
          _(msg.hashtags).intersection(current_channels).length
      else
        messages
  ).
  controller('AppCtrl', ($scope, $filter, $http, socket, hashchange) ->
    window.scope = $scope

    first_connection = true

    $scope.channels = []
    $scope.current_channels = []
    $scope.messages = []
    $scope.message =
      content: ""

    $scope.me =
      username: ""
      avatar: ""
      userAgent: navigator.userAgent

    $scope.$watch "channels", (n,o) ->
      console.log "channels, n", n, "o", o
    , true

    $scope.poiShow = false

    # Map Refresh
    $scope.isMapVisible = false

    ### Mediau queries ###
    setTimeout ( ->
      $scope.$apply ->
        mq = window.matchMedia("(min-width: 1280px)")
        if (mq.matches)
          $scope.isMapVisible = true
    ), 1000

    colorMarker = (chan) ->
      pos = _($scope.channels).map((channel) ->
          channel.name
        ).indexOf chan
      Math.round((19 / $scope.channels.length) * pos + 1)

    $scope.paneChanged = (selectedPane) ->

      if selectedPane.title is "Maps"
        $scope.isMapVisible = true
      else
        $scope.isMapVisible = false

      $scope.markers = []

      console.log "filter?",
      _($filter('matchCurrentChannels') $scope.messages, $scope.current_channels)
      .each (message) ->
        if message.poi
          $scope.markers.push(
            latitude: message.poi.coord[0]
            longitude: message.poi.coord[1]
            infoWindow: message.poi.name
            icon: "/img/pins/pin-#{colorMarker message.hashtags[0]}.png"
          )
      console.log "markers", $scope.markers

    $scope.poiResults = []
    $scope.poiMessage =
      name: ""
      coord: []

    $scope.typeahead = (search)->
      if search.length > 2
        $http({
          url: "/_suggest_poi"
          method: "GET"
          params: {ll: $scope.center.latitude + ',' + $scope.center.longitude, search: search}
        }).success( (data) ->
          console.log data
          $scope.poiResults = data.response.minivenues
        )

    $scope.addPoi = (name, lat, lng)->
      console.log "addPoi"
      $scope.poiMessage.name = name
      $scope.poiMessage.coord = [lat, lng]
      $("#local_search").val("")
      $scope.togglePoiShow()

    $scope.togglePoiShow = ->
      $scope.poiShow = !$scope.poiShow
      if $scope.poiShow
        $("#local_search").focus()

    $scope.toggleChannel = (channel, event) ->
      removed = false
      $scope.current_channels = _($scope.current_channels)
        .reject (chan) ->
          chan is channel &&
            removed = true
      unless removed
        $scope.current_channels.push channel


      console.log "toggleChannel", arguments, event
      event.preventDefault()

    extractHashtags = (text) ->
      _(text.match(/#(\w+)/g)).map (ht) -> ht.slice(1)

    $scope.sendMessage = ->
      console.log "Sending.Message", $scope.message.content
      return unless $scope.message.content
      if not $scope.me.username
        setTimeout ->
          $("#pseudoprompt").focus()
          console.log "Setting focus on", $("#pseudoprompt").first()
        return $scope.usernamePrompt = true
      $scope.usernamePrompt = false
      socket.emit "post",
        author: $scope.me.username
        content: $scope.message.content
        hashtags: extractHashtags $scope.message.content
        poi: if $scope.poiMessage.name then $scope.poiMessage else null
      $scope.message.content = ""
      $scope.poiMessage =
        name: ""
        coord: []


    add_or_update_channel = (room) ->
      unless update_channel_state room.name, room
        $scope.channels.push room

    add_or_not_message = (msg) ->
      msg.content = msg.content?.autoLink(target: "_blank", $scope)
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
        window.location.hash = "#"+new_arr.join("#")
        console.log "currents_channels", new_arr, old_arr
        # Trick to join on first init
        if new_arr is old_arr
          old_arr = []
        # Chan to Join
        _(new_arr).difference(old_arr).forEach (chan) ->
          console.log "Joining #{chan}"

          socket.emit "join", chan , (channel) ->
            add_or_update_channel _(channel).defaults(
              joined: true
            )
            _(channel.messages).each (msg) ->
              add_or_not_message msg
        console.log "leave",  _(old_arr).difference(new_arr)
        # Chan to Leave
        _(old_arr).difference(new_arr).forEach (chan) ->
          console.log "Leaving #{chan}"
          socket.emit "leave", chan
          update_channel_state chan, joined: false

        if not $scope.current_channels?.length and not $scope.messages?.length
          socket.emit "get_posts", (msgs) ->
            console.log "get_posts", msgs
            _(msgs).each (msg) ->
              add_or_not_message msg




      , true

      hashchange.on current_channel = (hash) ->
        cur_hash_chans = (hash ? window.location.hash).split(/\#/)[1..-1]
        unless _($scope.current_channels).isEqual cur_hash_chans
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
          for room in rooms
            add_or_update_channel room if room.name

    socket.on "room_update", (room) ->
      console.log "room_update", room
      add_or_update_channel room

    # Google Maps
    $scope.zoom = 13
    $scope.center = {
      latitude: 45.1911576 #40.705578
      longitude: 5.7186758 #-73.978004
    }

    if navigator.geolocation
      navigator.geolocation.getCurrentPosition((position) ->
        console.log position
        ###
        $scope.$apply ->
          $scope.center = {
            latitude: position.coords.latitude
            longitude: position.coords.longitude
          }
        ###
      )

    $scope.markers = []

    socket.on "post", (post) ->
      console.log "post", post
      if (_(post.hashtags).intersection($scope.current_channels).length > 0) or
        ($scope.current_channels.length is 0)
          add_or_not_message post
  ).
  directive('enterSubmit', ->
    {
      restrict: 'A'
      link: (scope, element, attrs) ->
        submit = false

        $(element).on({
          keydown: (e) ->
            submit = false

            if (e.which is 13 && !e.shiftKey)
              submit = true
              e.preventDefault()

          keyup: () ->
            if submit
              scope.$eval( attrs.enterSubmit )

              # flush model changes manually
              scope.$digest()
        })
    }
  )

