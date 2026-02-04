
using Toybox.System;
using Toybox.Lang;



class DummyBleDelegateDemo extends DummyBleDelegate {

    private var tk = 0;

    function initialize() {
        DummyBleDelegate.initialize();
    }
    public function valueAreValid() as Toybox.Lang.Boolean {
        return true;
    }
    function msgstring() as Toybox.Lang.String {
        return "demo";
    }
    function isFake() as Toybox.Lang.Boolean {
        return false;
    }
    public function tick() {
        tk = tk+1;
        var k = (tk/50)%2;
        if (k==0) { self.temperature = 73; }
        else { self.temperature = -123; }
    }
}