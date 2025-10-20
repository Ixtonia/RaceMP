var app = angular.module('beamng.apps');

app.directive('racepositon', [function () {
    return {
        templateUrl: '/ui/modules/apps/racepositon/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("RaceboardController", ['$scope', function ($scope) {
    $scope.raceData = [];
    $scope.$on('updateRaceboard', function (event, sortedRaceDataJson) {
        var raceData = JSON.parse(sortedRaceDataJson);
        $scope.raceData = raceData;
    });
}]);
