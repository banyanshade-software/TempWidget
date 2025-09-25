using Toybox.System;
using Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Timer;
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
    MODE_PROXY,
    MODE_PROVISION
}

class MyBleDelegate extends Ble.BleDelegate {
    private var timer = new Timer.Timer();
    //public var networkManager;

    hidden var scanResults = [];
    hidden var mode = null;
    hidden var device;
    hidden var currentPacket;
    hidden var connected = false;
    hidden var scanning = false;
    var nscan = 0;
    var knownDevices = {};

    function msgstring()  {
        if (self.isScanning()) {
            return "Scan "+nscan;
        } else if (self.isConnected()) {
            return "Connected "+nscan;
        } else {
            return "Not connected "+nscan;
        }
        
        //return "Hello, World! ";
    } 

    function initialize(/*networkManager*/) {
        System.println("MyBleDelegate init");
        BleDelegate.initialize();
        nscan = 0;
        if ((0)) {
            var t = App.getApp().getProperty("kdev");
            if (t != null) {
                self.knownDevices = t as Lang.Dictionary;
                System.println("loaded knownDevices: " + self.knownDevices.toString());
            } else {
                System.println("no knownDevices found");
            }
            self.knownDevices["4A0D"] = "TP357_4A0D";
            //App.getApp().setProperty( "kdev", self.knownDevices);
        } else if ((0)) { 
            var t = Stor.getValue("knownDevices");
            if (t != null) {
                self.knownDevices = t as Lang.Dictionary;
                System.println("loaded knownDevices: " + self.knownDevices.toString());
            } else {
                System.println("no knownDevices found");
            }
            if ((1)) {
                self.knownDevices["4A0D"] = "TP357_4A0D";
                Stor.setValue(  "knownDevices", self.knownDevices);
            }
        } else {
            var t = Prop.getValue("k1");
            System.println("property k1: " + t);
            Prop.setValue("k1", "new k1 value"); 
            var t2 = Prop.getValue("k1");
            System.println("property k1 after set: " + t2);   
        }
        //self.networkManager = networkManager;
        //self.networkManager.setCallback(self.weak());
    }
    // callback function for the timer

    function needsDisplay() {
        Ui.requestUpdate();
    }
        
    function timerDone() {
        self.scanning = false;
        self.onScanFinished();
        self.needsDisplay();
    }

    function startScanning() {
        self.disconnect();
        self.scanResults = [];
        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        // scan for five seconds
        timer.start(method(:timerDone), 5000, false);
        //self.mode = mode;
        self.scanning = true;
    }

    // helper function to see if a ScanResult has a specific service
    private function hasService(iterator, serviceUuid) {
        for (var uuid = iterator.next(); uuid != null; uuid = iterator.next()) {
            if (uuid.equals(serviceUuid)) {
                return true;
            }
        }
        return false;
    }

    // overrides the superclass - filters the results
    // https://github.com/pedasmith/BluetoothDeviceController/blob/6883b70da7852fa4c70dede47af628a72baff380/BluetoothDeviceController/Assets/CharacteristicsData/ThermoPro_TP357_Temperature.json#L4

    function onScanResults(iterator) {
        System.println("MyBleDelegate onScanResults");
        for (;;) {
            var scanResult = iterator.next(); // as Ble.ScanResult;
            if (scanResult == null) { 
                break; 
            }
            var r = scanResult as Ble.ScanResult;
            //self.scanResults.add(r);
            nscan = nscan + 1;
            var n = r.getDeviceName();
            if (n == null) {
                n = "unknown";
            } else {
                System.println("got name: " + n);
            }
            System.println("scan result: " 
                //+ r.getDeviceName() 
                + "appearance " + r.getAppearance()
                //+ ", address " + r.getAddress()
                + ", name " + n
                + " - RSSI: " + r.getRssi() 
                //+ " - uuids: " + r.getServiceUuids().toString()
                );
            var serv = r.getServiceUuids();
            if (serv != null) {
                for (var u = serv.next(); u != null; u = serv.next()) {
                    var su = u as Ble.Uuid;
                    System.println("   s_uuid: " + su.toString());
                    var d = r.getServiceData(su);
                    if (d != null) {
                        System.println("     s_data: " + d);
                    } else {
                        System.println("     s_data: <none>");  
                    }
                }
            }
            var mi = r.getManufacturerSpecificDataIterator(); 
            for (;;) {
                var m = mi.next();
                if (m == null) { break; }
                var d = m as Lang.Dictionary;
                // https://www.bluetooth.com/specifications/assigned-numbers/
                System.println("   m_manuf: 0x" + d[:companyId].format("%04X") );
                System.println("   m_data: " + d[:data].toString());
                //System.println("   keys: " + d.keys().toString()); 
                var cie = d[:companyId];
                if (cie == 0x4C) {
                    System.println("   Apple device");
                } else if (cie == 0x75) {
                    System.println("   Samsung device");
                } else if (cie == 0x87) {
                    System.println("   Garmin device");
                } else {
                    // 0x
                    // 0x0310 SGL Italia (Bose??)
                    // 0x0312 Ducere Technologies (Jabra)
                    System.println("   Other device");
                }
                
                var msdData = d[:data] as Toybox.Lang.ByteArray;
                var idx = msdData.size();
                if (idx >= 2) {
                    var msd = msdData.decodeNumber(Toybox.Lang.NUMBER_FORMAT_UINT16, { :offset => 0, :endianness => Toybox.Lang.ENDIAN_LITTLE });
                    System.println("   m_data16: 0x" + msd.format("%04X") );

                } else {
                    System.println("   m_data16: <2 bytes");
                }
            }   
      
        }
        /*
        for (var scanResult = iterator.next(); scanResult != null; scanResult = iterator.next()) {
            // find all unique devices that have the proxy or provision service
            //var res = scanResults as Ble.ScanResult;
            System.println("scan result: ");// + res.geteviceName() + " - RSSI: " + res.getRssi()    );

            //var serviceUuid = null;
            /*
            if (self.mode == MODE_PROXY) {
                serviceUuid = PROXY_SERVICE_UUID;
            } else if (self.mode == MODE_PROVISION) {
                serviceUuid = PROVISION_SERVICE_UUID;
            }
            

            if (serviceUuid != null && hasService(scanResult.getServiceUuids(), serviceUuid)) {
                var add = true;
                for (var i = 0; i < self.scanResults.size(); i++) {
                    if (self.scanResults[i].isSameDevice(scanResult)) {
                        add = false;
                        break;
                    }
                }
                if (add) {
                    self.scanResults.add(scanResult);
                }
            }
        }*/
        self.needsDisplay();
    }


    // pairs with the device at the specified index of the scan results
    function connectToDevice(index) {
        self.disconnect();
        Ble.pairDevice(self.scanResults[index]);
        self.scanResults = [];
        self.needsDisplay();
    }

    // unpair the current device
    function disconnect() {
        if (self.connected) {
            Ble.unpairDevice(self.device);
            self.device = null;
            self.connected = false;
            self.onDisconnected();
        }
        self.needsDisplay();
    }

    // callback function for the BLE delegate (overrides superclass)
    function onConnectedStateChanged(device, state) {
        // if connected, send connection info to the network manager
        if (state == Ble.CONNECTION_STATE_CONNECTED && device != null) {
            self.device = device;
            /*
            var read = null;
            var write = null;
            if (self.mode == MODE_PROXY) {
                var service = self.device.getService(PROXY_SERVICE_UUID);
                if (service != null) {
                    read = service.getCharacteristic(PROXY_SERVICE_OUT);
                    write = service.getCharacteristic(PROXY_SERVICE_IN);
                }
            } else if (self.mode == MODE_PROVISION) {
                var service = device.getService(PROVISION_SERVICE_UUID);
                if (service != null) {
                    read = service.getCharacteristic(PROVISION_SERVICE_OUT);
                    write = service.getCharacteristic(PROVISION_SERVICE_IN);
                }
            }
            if (read != null && write != null) {
                self.networkManager.setCharacteristics(read, write);
                self.connected = true;
                // if provisioning, start the process
                if (self.mode == MODE_PROVISION) {
                    self.networkManager.provisioningManager.startProvisioning();
                }
                self.onConnected();
            }*/
        } else {  // clear the connection parameters
            if (device != null) {
                Ble.unpairDevice(device);
            }
            self.device = null;
            self.connected = false;
            //self.networkManager.setCharacteristics(null, null);
            self.onDisconnected();
        }
        self.needsDisplay();

    }

    // callback function from the BLE Delegate. Accepts data, figures out what to do with it
    function onCharacteristicChanged(characteristic, value) {
        //if (characteristic.getUuid().equals(PROXY_SERVICE_OUT) || characteristic.getUuid().equals(PROVISION_SERVICE_OUT)) {
        //    self.networkManager.processProxyData(value);
        //}
    }

    function isConnected() {
        return self.connected;
    }

    function isScanning() {
        return self.scanning;
    }

    // clears all known data of the mesh network
    function deleteAllData() {
        /*
        self.networkManager.keyManager.clearKeys();
        self.networkManager.deviceManager.reset();
        self.networkManager.provisioningManager.reset();
        self.networkManager.save();
        */
    }


    // *************** USER IMPLEMENTABLE FUNCTIONS ***************** //

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onNetworkPduReceived(bytes) {

        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onScanFinished() {
            self.needsDisplay();

            // use the connectToDevice(index) function and the
            // devices in the scanResults array to continue connecting
        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onConnected() {
            self.needsDisplay();

        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onDisconnected() {
            self.needsDisplay();

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
