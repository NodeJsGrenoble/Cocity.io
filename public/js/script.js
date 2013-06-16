// Generated by CoffeeScript 1.6.2
(function() {
  var autoLink,
    __slice = [].slice;

  angular.module('cocity', ["google-maps"]).directive('tabs', function() {
    return {
      restrict: 'E',
      transclude: true,
      scope: {
        paneChanged: '&'
      },
      controller: function($scope, $element) {
        var panes;

        panes = $scope.panes = [];
        $scope.select = function(pane) {
          angular.forEach(panes, function(pane) {
            return pane.selected = false;
          });
          pane.selected = true;
          return $scope.paneChanged({
            selectedPane: pane
          });
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
  }).filter("matchCurrentChannels", function() {
    return function(messages, current_channels) {
      console.log("Filtering", messages, current_channels, arguments);
      if (current_channels != null ? current_channels.length : void 0) {
        return _(messages).filter(function(msg) {
          return _(msg.hashtags).intersection(current_channels).length;
        });
      } else {
        return messages;
      }
    };
  }).controller('AppCtrl', function($scope, $filter, $http, socket, hashchange) {
    var add_or_not_message, add_or_update_channel, colorMarker, first_connection, update_channel_state;

    window.scope = $scope;
    first_connection = true;
    $scope.channels = [];
    $scope.current_channels = [];
    $scope.messages = [];
    $scope.message = {
      content: ""
    };
    $scope.me = {
      username: "",
      avatar: "",
      userAgent: navigator.userAgent
    };
    $scope.$watch("channels", function(n, o) {
      return console.log("channels, n", n, "o", o);
    }, true);
    $scope.isMapVisible = false;
    colorMarker = function(chan) {
      var pos;

      pos = _($scope.channels).map(function(channel) {
        return channel.name;
      }).indexOf(chan);
      return Math.round((19 / $scope.channels.length) * pos + 1);
    };
    $scope.paneChanged = function(selectedPane) {
      if (selectedPane.title === "Maps") {
        $scope.isMapVisible = true;
      } else {
        $scope.isMapVisible = false;
      }
      $scope.markers = [];
      console.log("filter?", _($filter('matchCurrentChannels')($scope.messages, $scope.current_channels)).each(function(message) {
        console.log("colorMarker", "http://" + window.location.host + "/img/pin-" + (colorMarker(message.hashtags[0])) + ".png");
        return $scope.markers.push({
          latitude: message.poi.coord[0],
          longitude: message.poi.coord[1],
          infoWindow: message.poi.name,
          icon: "/img/pins/pin-" + (colorMarker(message.hashtags[0])) + ".png"
        });
      }));
      return console.log("markers", $scope.markers);
    };
    $scope.poiResults = [];
    $scope.poiMessage = {
      name: "",
      lat: 0,
      lng: 0
    };
    $scope.typeahead = function(search) {
      if (search.length > 2) {
        return $http({
          url: "/_suggest_poi",
          method: "GET",
          params: {
            ll: $scope.center.latitude + ',' + $scope.center.longitude,
            search: search
          }
        }).success(function(data) {
          console.log(data);
          return $scope.poiResults = data.response.minivenues;
        });
      }
    };
    $scope.addPoi = function(name, lat, lng) {
      $scope.poiMessage.name = name;
      $scope.poiMessage.lat = lat;
      $scope.poiMessage.lng = lng;
      return $scope.poiShow = !$scope.poiShow;
    };
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
      if (!$scope.me.username) {
        return $scope.usernamePrompt = true;
      }
      $scope.usernamePrompt = false;
      socket.emit("post", {
        author: $scope.me.username,
        content: $scope.message.content,
        hashtags: $scope.current_channels
      });
      return $scope.message.content = "";
    };
    add_or_update_channel = function(room) {
      if (!update_channel_state(room.name, room)) {
        return $scope.channels.push(room);
      }
    };
    add_or_not_message = function(msg) {
      msg.content = msg.content.autoLink();
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
          return socket.emit("join", chan, function(channel) {
            add_or_update_channel(_(channel).defaults({
              joined: true
            }));
            return _(channel.messages).each(function(msg) {
              return add_or_not_message(msg);
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
    $scope.zoom = 13;
    $scope.center = {
      latitude: 45.1911576,
      longitude: 5.7186758
    };
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function(position) {
        return console.log(position);
        /*
        $scope.$apply ->
          $scope.center = {
            latitude: position.coords.latitude
            longitude: position.coords.longitude
          }
        */

      });
    }
    $scope.markers = [];
    return socket.on("post", function(post) {
      console.log("post", post);
      if ((_(post.hashtags).intersection($scope.current_channels).length > 0) || ($scope.current_channels.length === 0)) {
        return add_or_not_message(post);
      }
    });
  }).directive('enterSubmit', function() {
    return {
      restrict: 'A',
      link: function(scope, element, attrs) {
        var submit;

        submit = false;
        return $(element).on({
          keydown: function(e) {
            submit = false;
            if (e.which === 13 && !e.shiftKey) {
              submit = true;
              return e.preventDefault();
            }
          },
          keyup: function() {
            if (submit) {
              scope.$eval(attrs.enterSubmit);
              return scope.$digest();
            }
          }
        });
      }
    };
  });

  /* String HTTP Linker
  */


  autoLink = function() {
    var k, linkAttributes, option, options, pattern, v;

    options = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    pattern = /(^|\s)((?:https?|ftp):\/\/[\-A-Z0-9+\u0026@#\/%?=~_|!:,.;]*[\-A-Z0-9+\u0026@#\/%=~_|])/gi;
    if (!(options.length > 0)) {
      return this.replace(pattern, "$1<a href='$2'>$2</a>");
    }
    option = options[0];
    linkAttributes = ((function() {
      var _results;

      _results = [];
      for (k in option) {
        v = option[k];
        if (k !== 'callback') {
          _results.push(" " + k + "='" + v + "'");
        }
      }
      return _results;
    })()).join('');
    return this.replace(pattern, function(match, space, url) {
      var link;

      link = (typeof option.callback === "function" ? option.callback(url) : void 0) || ("<a href='" + url + "'" + linkAttributes + ">" + url + "</a>");
      return "" + space + link;
    });
  };

  String.prototype.autoLink = autoLink;

}).call(this);
