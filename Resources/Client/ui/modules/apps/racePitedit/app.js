var app = angular.module('beamng.apps');

app.directive('racePitedit', [function () {
    return {
        templateUrl: '/ui/modules/apps/racePitedit/app.html', // Убедитесь, что путь к шаблону корректен
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller('RacePiteditController', ['$scope', function () {
    $scope.Fpressure = 22
    $scope.Rpressure = 22
    this.setFpressure = function () {
        bngApi.engineLua(`extensions.gameplay_traffic.setTrafficVars( ${bngApi.serializeToLua({baseAggression: this.aggression, frontPressure: this.Fpressure})} )`);
    }
    this.setRpressure = function () {
        bngApi.engineLua(`extensions.gameplay_traffic.setTrafficVars( ${bngApi.serializeToLua({baseAggression: this.aggression, rearPressure: this.Rpressure})} )`);
    }
    this.btnSendTireType = function () {
        const vars = {
            tirepressure_R: this.Rpressure,
            tirepressure_F: this.Fpressure
        };
        bngApi.engineLua(`sendtire(${bngApi.serializeToLua(vars)})`);
    }
}]);