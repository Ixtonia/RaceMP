var app = angular.module('beamng.apps');

app.directive('racepositonteam', [function () {
    return {
        templateUrl: '/ui/modules/apps/racepositonteam/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("RaceboardControllerTeam", ['$scope', function ($scope) {
    $scope.teamData = [];

    $scope.$on('updateTeamBoard', function (event, sortedTeamDataJson) {
        var teamData = JSON.parse(sortedTeamDataJson);
        $scope.$apply();
        $scope.teamData = teamData;
    });
}]);
