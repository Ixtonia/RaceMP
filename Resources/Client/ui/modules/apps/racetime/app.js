var app = angular.module('beamng.apps');

app.directive('racetimebrt', [function () {
    return {
        templateUrl: '/ui/modules/apps/racetime/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("BalanceInit", ['$scope', function ($scope) {

    $scope.flagStatus1 = 'rgba(0, 0, 0, 0)';
    $scope.flagStatus2 = 'rgba(0, 0, 0, 0)';
    $scope.flagStatus3 = 'rgba(0, 0, 0, 0)';
    $scope.flagStatus4 = 'rgba(0, 0, 0, 0)';
    $scope.flagStatus5 = 'rgba(0, 0, 0, 0)';

    $scope.$on('updateFlag', function (event, flag) {
        $scope.flagStatus1 = flag.flag1;
        $scope.flagStatus2 = flag.flag2;
        $scope.flagStatus3 = flag.flag3;
        $scope.flagStatus4 = flag.flag4;
        $scope.flagStatus5 = flag.flag5;
    });
    
    $scope.balances = {
        balance2: "",
        balance3: "",
        balance5: "",
        balance6: "",
    };

    $scope.$on('setRP-Balance2', function (event, BalanceUser) {
        $scope.balances.balance2 = BalanceUser;
    });
    $scope.$on('setRP-Balance3', function (event, BalanceUser) {
        $scope.balances.balance3 = BalanceUser;
    });
    $scope.$on('setRP-Balance5', function (event, BalanceUser) {
        $scope.balances.balance5 = BalanceUser;
    });
    $scope.$on('setRP-Balance6', function (event, BalanceUser) {
        $scope.balances.balance6 = BalanceUser;
    });
    $scope.$on('DiffTimeCount', function (event, BalanceUser) {
        $scope.balances.balance8 = BalanceUser;
    });
}]);
