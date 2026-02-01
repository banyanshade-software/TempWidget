import Toybox.Application;
import Toybox.Lang;
using Toybox.WatchUi as Ui;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as System;  

function _timstr(){
    var t = System.getClockTime();
    var s = t.hour.format("%02d") + ":" 
        + t.min.format("%02d") + ":" 
        + t.sec.format("%02d");
    return s;
}

// see https://github.com/blueacorn/Infocal/blob/87783573a84487bfd2d1f09cacf266a5b05ebbe4/source/utils/Debug.mc#L4

(:debug)
public function debug_prt(format as String, params as Object or Array or Null) as Void {
    var s = _timstr();
    System.print(s + " ");
    if (params instanceof Array) {
        System.println(Lang.format(format, params));
    } else {
        System.println(Lang.format(format, [params]));
    }
}
(:release)
public function debug_prt(format as String, params as Object or Array or Null) as Void {
    // do nothing
}   


class Thermo357App extends Application.AppBase {
    protected var bleDelegate;
    //hidden var mapper;
    protected var view;
    protected var menudelegate;
    protected var bleSupported as Lang.Boolean;


    function initialize() {
        AppBase.initialize();
        var deviceSettings = System.getDeviceSettings();
        var apiLevel = deviceSettings.monkeyVersion;
        debug_prt("Thermo357App initialize() API level: " + apiLevel, null);

        // Try to check if the module is available

        if (true) {
            self.bleSupported = false;
            var t = new DummyBleDelegateDemo();
            self.bleDelegate  = t;        
        } else if (Toybox has :BluetoothLowEnergy) {
            self.bleSupported = true;
            //self.mapper = new NameMapper();
            var t = new MyBleDelegate();
            self.bleDelegate  = t;
        } else {
            self.bleSupported = false;
            var t = new DummyBleDelegate();
            self.bleDelegate  = t;
        }
        debug_prt("BLE Module Available: " + bleSupported, null);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        debug_prt("Thermo357App onStart()", null);
        if (self.bleSupported) {
            //self.mapper.initialize();
            Ble.setDelegate(self.bleDelegate);
            // 2025-09-30 on station without BLE dongle, startScanning() 
            // would crash the app. For debug/dev we may turn it off.
            if ((1)) { self.bleDelegate.startScanning(); }
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        menudelegate = new BleMenuDelegate();
        view = new TemperatureDatafield(/*self.mapper,*/ self.bleDelegate);
        return [view, menudelegate];
        //return [view];
    }

}

function getApp() as Thermo357App {
    return Application.getApp() as Thermo357App;
}
