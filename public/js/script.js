$(document).ready(function(){
  var navigation = responsiveNav("#nav", {
    label: "list",
    openPos: "static",
  });
});

function UsersCtrl($scope) {
  $scope.users = [
    "alice",
    "bob"
  ];
}

