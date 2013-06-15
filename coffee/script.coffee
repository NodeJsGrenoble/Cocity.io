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

      @.addPane = (pane) ->
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
  controller('AppCtrl', ($scope) ->
    $scope.channels = [
      {
        name: 'p0rn',
        users: 34,
        joined: true
      },
      {
        name: 'redbull',
        users: 54
      }
    ]

    $scope.messages = [
      {
        author: 'Aristote',
        content: 'We are what we repeatedly do. Excellence then, is not an act, but a habit.',
        hashtags: [
          'quotes',
          'fames'
        ]
      },
      {
        author: 'unknown',
        content: 'The people you spend time with will shape and define you. Choose wisely.'
      }
    ]
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

    map.setCenter(new google.maps.LatLng(lat,lng));

  # Center if geoloc
  if navigator.geolocation
    navigator.geolocation.getCurrentPosition(centerMap);

google.maps.event.addDomListener(window, 'load', initialize);
