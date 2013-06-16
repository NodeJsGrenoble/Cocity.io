// Generated by CoffeeScript 1.6.2
(function() {
  var __slice = [].slice;

  angular.module('cocity', ["google-maps"]).directive('tabs', function() {
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
  }).factory("hashchange", function($rootScope) {
    var last_hash;

    last_hash = window.location.hash;
    return {
      on: function(cb) {
        console.log("on hashchange");
        return setInterval(function() {
          if (last_hash !== window.location.hash) {
            console.log("onHashChange", window.location.hash);
            last_hash = window.location.hash;
            return $rootScope.$apply(function() {
              return typeof cb === "function" ? cb(last_hash) : void 0;
            });
          }
        }, 100);
      }
    };
  }).factory("socket", function($rootScope) {
    var socket;

    socket = io.connect();
    console.log("connected?");
    return {
      on: function(event, cb) {
        return socket.on(event, function() {
          var args;

          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return $rootScope.$apply(function() {
            return cb.apply(socket, args);
          });
        });
      },
      emit: function(event, data, ack) {
        if (typeof data === "function") {
          ack = data;
          data = "";
        }
        return socket.emit(event, data, function() {
          var args;

          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return $rootScope.$apply(function() {
            return ack != null ? ack.apply(socket, args) : void 0;
          });
        });
      }
    };
  }).controller('AppCtrl', function($scope, socket, hashchange) {
    var add_or_not_message, add_or_update_channel, first_connection, update_channel_state;

    window.scope = $scope;
    first_connection = true;
    $scope.channels = [];
    $scope.current_channels = [];
    $scope.messages = [];
    $scope.message = {
      content: "Enter your message here"
    };
    $scope.me = {
      username: "Anon" + (Math.round(Math.random() * 90000) + 10000),
      avatar: "",
      userAgent: navigator.userAgent
    };
    $scope.$watch("channels", function(n, o) {
      return console.log("channels, n", n, "o", o);
    }, true);
    $scope.toggleChannel = function(channel, event) {
      var removed;

      removed = false;
      $scope.current_channels = _($scope.current_channels).reject(function(chan) {
        return chan === channel && (removed = true);
      });
      if (!removed) {
        $scope.current_channels.push(channel);
      }
      console.log("toggleChannel", arguments, event);
      return event.preventDefault();
    };
    $scope.sendMessage = function() {
      console.log("Sending.Message", $scope.message.content);
      return socket.emit("post", {
        author: $scope.me.username,
        content: $scope.message.content,
        hashtags: $scope.current_channels
      });
    };
    add_or_update_channel = function(room) {
      if (!update_channel_state(room.name, room)) {
        return $scope.channels.push(room);
      }
    };
    add_or_not_message = function(msg) {
      if (!_($scope.messages).find(function(message) {
        return message.id === msg.id;
      })) {
        return $scope.messages.push(msg);
      }
    };
    update_channel_state = function(name, state) {
      var chan, k, v, _results;

      if (chan = _($scope.channels).find(function(chan) {
        return chan.name === name;
      })) {
        console.log("Found channel " + name);
        _results = [];
        for (k in state) {
          v = state[k];
          console.log("Updating channel " + name + "." + k + " = " + v);
          _results.push(chan[k] = v);
        }
        return _results;
      } else {
        return console.log("Not found channel " + name);
      }
    };
    socket.on("connect", function() {
      var current_channel,
        _this = this;

      $scope.$watch("current_channels", function(new_arr, old_arr) {
        window.location.hash = "#" + new_arr.join("#");
        console.log("currents_channels", new_arr, old_arr);
        if (new_arr === old_arr) {
          old_arr = [];
        }
        _(new_arr).difference(old_arr).forEach(function(chan) {
          console.log("Joining " + chan);
          return socket.emit("join", chan, function(users) {
            console.log("Joined " + chan + ", Users", users.length);
            return add_or_update_channel({
              name: chan,
              users: users.length,
              joined: true
            });
          });
        });
        console.log("leave", _(old_arr).difference(new_arr));
        return _(old_arr).difference(new_arr).forEach(function(chan) {
          console.log("Leaving " + chan);
          socket.emit("leave", chan);
          return update_channel_state(chan, {
            joined: false
          });
        });
      }, true);
      hashchange.on(current_channel = function(hash) {
        var cur_hash_chans;

        cur_hash_chans = (hash != null ? hash : window.location.hash).split(/\#/).slice(1);
        if (!_($scope.current_channels).isEqual(cur_hash_chans)) {
          return $scope.current_channels = (hash != null ? hash : window.location.hash).split(/\#/).slice(1);
        }
      });
      current_channel();
      if (!first_connection) {
        window.location.reload();
      }
      first_connection = false;
      return socket.emit("me", $scope.me, function() {
        return socket.emit("list_rooms", function(rooms) {
          var room, _i, _len, _results;

          console.log("list_rooms", rooms);
          _results = [];
          for (_i = 0, _len = rooms.length; _i < _len; _i++) {
            room = rooms[_i];
            _results.push(add_or_update_channel(room));
          }
          return _results;
        });
      });
    });
    socket.on("room_update", function(room) {
      console.log("room_update", room);
      return add_or_update_channel(room);
    });
    $scope.center = {
      latitude: 45.1911576,
      longitude: 5.7186758
    };
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        return $scope.$apply(function() {
          return $scope.center = {
            latitude: position.coords.latitude,
            longitude: position.coords.longitude
          };
        });
      });
    }
    $scope.markers = [];
    $scope.zoom = 6;
    return socket.on("post", function(post) {
      console.log("post", post);
      if ((_(post.hashtags).intersection($scope.current_channels).length > 0) || ($scope.current_channels.length === 0)) {
        return add_or_not_message(post);
      }
    });
  });

}).call(this);
