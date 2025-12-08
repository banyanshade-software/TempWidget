import Toybox.Application;
import Toybox.Lang;
using Toybox.WatchUi as Ui;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.System as System;  

function timstr(){
    var t = System.getClockTime();
    var s = t.hour.format("%02d") + ":" 
        + t.min.format("%02d") + ":" 
        + t.sec.format("%02d");
    return s;
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
        System.println("Thermo357App initialize() API level: " + apiLevel);

        // Try to check if the module is available

        if (Toybox has :BluetoothLowEnergy) {
            self.bleSupported = true;
            //self.mapper = new NameMapper();
            var t = new MyBleDelegate();
            self.bleDelegate  = t;
        } else {
            self.bleSupported = false;
            var t = new DummyBleDelegate();
            self.bleDelegate  = t;
        }
        System.println("BLE Module Available: " + bleSupported);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("Thermo357App onStart() "+timstr());
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
