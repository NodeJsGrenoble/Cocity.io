// Generated by CoffeeScript 1.6.2
(function() {
  $(function() {
    var navigation;

    return navigation = responsiveNav("#nav", {
      label: "list",
      openPos: "static"
    });
  });

  angular.module('components', []).directive('tabs', function() {
    return {
      restrict: 'E',
      transclude: true,
      scope: {},
      controller: function($scope, $element) {
        var panes;

        panes = $scope.panes = [];
        $scope.select = function(pane) {
          angular.forEach(panes, function(pane) {
            return pane.selected = false;
          });
          return pane.selected = true;
        };
        return this.addPane = function(pane) {
          if (panes.length === 0) {
            $scope.select(pane);
          }
          return panes.push(pane);
        };
      },
      template: '<div class="tabs">\n  <ul class="tab-bar">\n    <li ng-repeat="pane in panes" class="tab-bar__tab">\n      <a href="" class="tab-bar__link" ng-class="{\'is-active\':pane.selected}" ng-click="select(pane)">{{pane.title}}</a>\n    </li>\n  </ul>\n  <div class="tab-content" ng-transclude></div>\n</div>',
      replace: true
    };
  }).directive('pane', function() {
    return {
      require: '^tabs',
      restrict: 'E',
      transclude: true,
      scope: {
        title: '@'
      },
      link: function(scope, element, attrs, tabsCtrl) {
        return tabsCtrl.addPane(scope);
      },
      template: '<div class="tab-pane" ng-class="{\'is-active\': selected}" ng-transclude>\n</div>',
      replace: true
    };
  }).controller('AppCtrl', function($scope) {
    return $scope.channels = [
      {
        name: 'p0rn',
        users: 34
      }, {
        name: 'redbull',
        users: 54
      }
    ];
  });

}).call(this);
