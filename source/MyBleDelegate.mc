using Toybox.System;
using Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;
//using Toybox.Timer; // Details: Module 'Toybox.Timer' not available to 'Data Field'

using Toybox.WatchUi as Ui; // to be removed later
using Toybox.Application.Storage as Stor;
using Toybox.Application.Properties as Prop;
using Toybox.Application as App;
//using Toybox.Cryptography as Crypto;

// https://github.com/garmin/connectiq-apps/blob/e26454bff1ab9f9e04dce20b7f6b6d2f9cd7155c/barrels/BluetoothMeshBarrel/source/Network/MeshDelegate.mc#L39

/*
since we want to run on Edge Explore, we stay on API level 3.1.0
*/

enum {
    MODE_NONE,           // init value, not used
    MODE_SCAN_NOKN,      // scan for devices, no known devices yet
    MODE_SCAN_KN,        // scan for devices,  known device recorded but not seen
    MODE_SCAN_REG,       // known device seen, regularly scanning for update
    MODE_SCAN_LOW,       // no device, long spacing scanning
    
}

class MyBleDelegate extends Ble.BleDelegate {
    protected var namemapper;
    //hidden var scanResults = [] as Lang.Array<Ble.ScanResult>;

    hidden var mode = MODE_NONE;
    protected var regdev as Ble.ScanResult or Null = null;
    //hidden var device as Ble.Device or Null = null;
    protected var t0 = 0;
    protected var tickValue = 0;
    
    protected var valueUpdatedTick = 0;
    public var temperature = 0; // in 0.1 degC
    public var humidity = 0;    // in % RH

    
    /*
    * (2025-09-29)
    * this is still experimental, and includes a lot of code
    * copied from the MeshDelegate example code, and not used
    * Currently we just scan for devices, as temperature
    * and humidity are broadcasted, and we dont need
    * to connect/pair to the devices.
    * The code will be cleaned up later.
    *
    * Nothing is done yet to limit power consumption.
    * (we should probably not scan all the time, as having temperature every
    * few minutes is  sufficient)
    */ 

    function initialize(nm) {
        System.println("MyBleDelegate init");
        BleDelegate.initialize();
        self.namemapper = nm;
        self.mode = MODE_NONE;
        //registerMyProfile();
    }
    /*
    function needsDisplay() {
        Ui.requestUpdate();
    }*/

/*
    public function valueUpdated() as Toybox.Lang.Boolean {
        if (self.valueUpdatedFlag == true) {
            self.valueUpdatedFlag = false;
            return true;
        }
        return false;
    }
    */

    public function valueAreValid() as Toybox.Lang.Boolean {
        if ((valueUpdatedTick>0) && (tickValue - valueUpdatedTick < 60*5)) {
           return true;
        }
        return false;
    }

    function msgstring() as Toybox.Lang.String {
        var s = "Mode: ";
        switch (self.mode) {
            case MODE_NONE:
                s += "NONE";
                break;
            case MODE_SCAN_KN:
                s += "SCANNING (kn)";
                break;
            case MODE_SCAN_NOKN:
                s += "SCANNING (NOkn)";
                break;
            case MODE_SCAN_REG:
                s += "REG";
                break;
            case MODE_SCAN_LOW:
                s += "LOW SCANNING";
                break;
            default:
                s += "UNKNOWN";
                break;
        }
        return s;
    }

    // callback function for the timer
    function tick() {
        //System.println("MyBleDelegate tick " + timstr());
        tickValue++;
        switch (mode) {
            case MODE_SCAN_LOW:
                if (tickValue-t0 > 300) {
                    self.startScanning();
                    // this set mode and t0 too
                }
                break;

            case MODE_SCAN_NOKN:
            case MODE_SCAN_KN:
                if (tickValue-t0 > 2*60) {
                    t0 = tickValue;
                    Ble.setScanState(Ble.SCAN_STATE_OFF);
                    mode = MODE_SCAN_LOW;
                }
                break;
            case MODE_SCAN_REG:
                if (tickValue-t0 > 2*60) {
                    self.startScanning();
                }  
                break;
            default:
                System.println("ooo" + mode);
                break;
        }
    }

    public function hasRegisteredDevice() as Toybox.Lang.Boolean {
        if (regdev == null) {
            return false;
        }
        return true;
    }

    public function registerDevice(r) {
        regdev = r;
    }
    public function registeredDevice() {
        return regdev;
    }

    function startScanning() 
    {
        self.t0 = tickValue;
        if (hasRegisteredDevice()) {
            self.mode = MODE_SCAN_KN;
        } else {
            self.mode = MODE_SCAN_NOKN;
        }

        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    }

  
    function stopScanning() {
        //self.disconnect();
        Ble.setScanState(Ble.SCAN_STATE_OFF);
    }

    

    // overrides the superclass - filters the results
    // https://github.com/pedasmith/BluetoothDeviceController/blob/6883b70da7852fa4c70dede47af628a72baff380/BluetoothDeviceController/Assets/CharacteristicsData/ThermoPro_TP357_Temperature.json#L4

    function onScanResults(iterator) {
        System.println("MyBleDelegate onScanResults "+timstr());
        //var need = false;
        for (;;) {
            var scanResult = iterator.next(); // as Ble.ScanResult;
            if (scanResult == null) { 
                break; 
            }
            var r = scanResult as Ble.ScanResult;
            var n = r.getDeviceName();
            if (n == null) {
                continue; //n = "unknown";
            } 
            System.println("got name: " + n);
            if ((n.length() >= 5) &&  n.substring(0, 5).equals("TP357")) {
                System.println("got a TP357 :" + n  + " - RSSI: " + r.getRssi());
                 
                if (mode == MODE_SCAN_NOKN) {
                    // any TP357 can be regisetered
                    registerDevice(r);
                } else {
                    if (self.registeredDevice().isSameDevice(r) == false) {
                        continue;
                    }
                }
                Ble.setScanState(SCAN_STATE_OFF);
                mode = MODE_SCAN_REG;
                t0 = tickValue;
                

                System.println("known device, processing data:");
                var raw = r.getRawData();
                System.println("  raw data" + raw);
                System.println("  len=" + raw.size());
                // https://github.com/theengs/decoder/blob/development/src/devices/TPTH_json.h#L19-L25
                var t = raw.decodeNumber(Toybox.Lang.NUMBER_FORMAT_SINT16, { :offset => 20,     :endianness => Toybox.Lang.ENDIAN_LITTLE });
                var h = raw.decodeNumber(Toybox.Lang.NUMBER_FORMAT_UINT8,  { :offset => 20+2,   :endianness => Toybox.Lang.ENDIAN_LITTLE });
                var f = raw.decodeNumber(Toybox.Lang.NUMBER_FORMAT_UINT8,  { :offset => 20+2+1, :endianness => Toybox.Lang.ENDIAN_LITTLE });
                        
                temperature = t;
                humidity = h;
                valueUpdatedTick = tickValue;


                System.println("  temp=" + t/10.0
                                    + "  hum=" + h
                                    + "  flag=" + f.format("%02X"));

                 
            }
        }
        //if (need) {
        //    self.needsDisplay();
        //} 
    }


    // *************** USER IMPLEMENTABLE FUNCTIONS ***************** //

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onNetworkPduReceived(bytes) {

        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onScanFinished() {
            //self.needsDisplay();

            // use the connectToDevice(index) function and the
            // devices in the scanResults array to continue connecting
        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onConnected() {
            //self.needsDisplay();

        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onDisconnected() {
            //self.needsDisplay();

        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onProvisioningFailed(reason) {
            // default implementation:
            System.println("Provisioning failed");
        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onProvisioningParamsRequested(capabilities) {
            // default implementation:
            // FIPS P-256 Elliptic Curve with no OOB public key, output OOB auth (blink)
            // with maximum size specified by the device
            System.println("Warning: using default onProvisioningParamsRequested function");
            //self.networkManager.provisioningManager.onProvisioningModeSelected(new StartPDU(0x00, 0x00, 0x00, 0x00, 0x00));
        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onAuthValueRequired() {
            System.println("Authentication value is required!");
            System.println("Override onAuthValueRequired() in MeshDelegate to prompt the user for the auth value");
            System.println("Use the onAuthValueCallback(authValue) method to continue the provisioning process");
        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onProvisioningComplete(device) {

        }

}
