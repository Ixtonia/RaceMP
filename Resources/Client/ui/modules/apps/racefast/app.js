var app = angular.module('beamng.apps');

app.directive('racefast', [function () {
    return {
        templateUrl: '/ui/modules/apps/racefast/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("Raceboardfast", ['$scope', function ($scope) {
    $scope.raceData = [];
    $scope.$on('updateRaceboardFast', function (event, sortedRaceDataFastJson) {
        var raceData = JSON.parse(sortedRaceDataFastJson);
        $scope.raceData = raceData;
    });
}]);
