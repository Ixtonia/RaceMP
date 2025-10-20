var app = angular.module('beamng.apps');

app.directive('racetable', [function () {
    return {
        templateUrl: '/ui/modules/apps/racetable/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("BalanceInit1", ['$scope', function ($scope) {
    $scope.balances = {
        balance1: "",
        balance4: "",
    };
    $scope.$on('setRP-Balance', function (event, BalanceUser) {
        $scope.balances.balance1 = BalanceUser;
    });
    $scope.$on('setRP-Balance4', function (event, BalanceUser) {
        $scope.balances.balance4 = BalanceUser;
    });
}]);
