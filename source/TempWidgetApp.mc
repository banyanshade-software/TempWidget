import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.BluetoothLowEnergy as Ble;
 

class TempWidgetApp extends Application.AppBase {
    hidden var bleDelegate;

    function initialize() {
        AppBase.initialize();
        self.bleDelegate = new MyBleDelegate();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        Ble.setDelegate(self.bleDelegate);
        self.bleDelegate.startScanning();
        //Ble.setScanState(Ble.SCAN_STATE_SCANNING); done by belDelegate.statrtScanning()
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new TempWidgetView(self.bleDelegate) ];
    }

}

function getApp() as TempWidgetApp {
    return Application.getApp() as TempWidgetApp;
}