import Toybox.Application;
import Toybox.Lang;
using Toybox.WatchUi as Ui;
using Toybox.BluetoothLowEnergy as Ble;
 

class TempWidgetApp extends Application.AppBase {
    hidden var bleDelegate;
    hidden var mapper;
    hidden var view;
    hidden var menudelegate;


    function initialize() {
        AppBase.initialize();
        self.mapper = new NameMapper();

        self.bleDelegate = new MyBleDelegate(self.mapper);
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        Ble.setDelegate(self.bleDelegate);
        // 2025-09-30 on station without BLE dongle, startScanning() 
        // would crash the app. For debug/dev we may turn it off.
        if ((0)) { self.bleDelegate.startScanning(); }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Ui.Views] or [Ui.Views, Ui.InputDelegates] {
        menudelegate = new BleMenuDelegate();
        view = new TempWidgetView(self.mapper);    
        return [view, menudelegate];
        //return [view];
    }

}

function getApp() as TempWidgetApp {
    return Application.getApp() as TempWidgetApp;
}