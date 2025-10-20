var app = angular.module('beamng.apps');

app.directive('racepos', [function () {
    return {
        templateUrl: '/ui/modules/apps/racepos/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("PositionLeftTop", ['$scope', function ($scope) {
    $scope.lapsClientCount = 0;
    $scope.lapCount = 0;
    
    $scope.$on('LapUpdt', function (event, lapsClientCount) {
        $scope.lapsClientCount = lapsClientCount;
    });

    $scope.$on('TotalLapsUpdt', function (event, lapCount) {
        $scope.lapCount = lapCount;
    });
}]);
