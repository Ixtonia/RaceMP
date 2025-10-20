var app = angular.module('beamng.apps');

app.directive('racesplit1', [function () {
    return {
        templateUrl: '/ui/modules/apps/racesplit/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("RaceSplitsController", ['$scope', function ($scope) {
    $scope.sector = {
         sector1time: "00.000",
         sector2time: "00.000",
         sector3time: "00.000",
        sector1delta: "+00.000",
        sector2delta: "+00.000",
        sector3delta: "+00.000",
        sector1color: "rgb(15, 15, 15)",
        sector2color: "rgb(15, 15, 15)",
        sector3color: "rgb(15, 15, 15)",
    };

    $scope.$on('setSplitA', function (event, dataSector) {
        $scope.sector.sector1time = dataSector;
    });
    $scope.$on('setSplitB', function (event, dataSector) {
        $scope.sector.sector2time = dataSector;
    });
    $scope.$on('setSplitC', function (event, dataSector) {
        $scope.sector.sector3time = dataSector;
    });
    $scope.$on('setDeltaSplitA', function (event, dataSector) {
        $scope.sector.sector1delta = dataSector;
    });
    $scope.$on('setDeltaSplitB', function (event, dataSector) {
        $scope.sector.sector2delta = dataSector;
    });
    $scope.$on('setDeltaSplitC', function (event, dataSector) {
        $scope.sector.sector3delta = dataSector;
    });
    $scope.$on('setDeltaSplitColorA', function (event, color) {
        $scope.sector.sector1color = color;
    });
    $scope.$on('setDeltaSplitColorB', function (event, color) {
        $scope.sector.sector2color = color;
    });
    $scope.$on('setDeltaSplitColorC', function (event, color) {
        $scope.sector.sector3color = color;
    });
}]);
