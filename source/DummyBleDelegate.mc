
using Toybox.System;
using Toybox.Lang;



class DummyBleDelegate {
    public var temperature = -182; // in 0.1 degC
    public var humidity = 52;    // in % RH

    function initialize() {
        System.println("MyBleDelegate init");
    }
    public function valueAreValid() as Toybox.Lang.Boolean {
        return false;
    }
    function msgstring() as Toybox.Lang.String {
        return "NO BLE";
    }
    function tick() {
    }
    function forceRefresh() {
    }
    function isFake() as Toybox.Lang.Boolean {
        return true;
    }   
}