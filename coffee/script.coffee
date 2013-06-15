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
        users: 34
      },
      {
        name: 'redbull',
        users: 54
      }
    ]
  )
