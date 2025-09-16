using Toybox.System;
using Toybox.Lang;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Timer;
using Toybox.WatchUi as Ui; // to be removed later

//using Toybox.Cryptography as Crypto;

// https://github.com/garmin/connectiq-apps/blob/e26454bff1ab9f9e04dce20b7f6b6d2f9cd7155c/barrels/BluetoothMeshBarrel/source/Network/MeshDelegate.mc#L39

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

    function msgstring()  {
        if (self.isScanning()) {
            return "Scanning..."+nscan;
        } else if (self.isConnected()) {
            return "Connected"+nscan;
        } else {
            return "Not connected"+nscan;
        }
        
        return "Hello, World!";
    } 

    function initialize(/*networkManager*/) {
        System.println("MyBleDelegate init");
        BleDelegate.initialize();
        nscan = 0;
        //self.networkManager = networkManager;
        //self.networkManager.setCallback(self.weak());
    }
    // callback function for the timer

    function timerDone() {
        self.scanning = false;
        self.onScanFinished();
        Ui.requestUpdate();
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
    function onScanResults(iterator) {
        System.println("MyBleDelegate onScanResults");
        for (var scanResult = iterator.next(); scanResult != null; scanResult = iterator.next()) {
            nscan = nscan + 1;
            // find all unique devices that have the proxy or provision service
            var res = scanResults as Ble.ScanResult;
            System.println("scan result: " + res.getDeviceName() + " - RSSI: " + res.getRssi()    );

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
            }*/
        }
        Ui.requestUpdate();
    }

    // pairs with the device at the specified index of the scan results
    function connectToDevice(index) {
        self.disconnect();
        Ble.pairDevice(self.scanResults[index]);
        self.scanResults = [];
        Ui.requestUpdate();
    }

    // unpair the current device
    function disconnect() {
        if (self.connected) {
            Ble.unpairDevice(self.device);
            self.device = null;
            self.connected = false;
            self.onDisconnected();
        }
                Ui.requestUpdate();
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
                Ui.requestUpdate();

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
                    Ui.requestUpdate();

            // use the connectToDevice(index) function and the
            // devices in the scanResults array to continue connecting
        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onConnected() {
            Ui.requestUpdate();

        }

        // THIS IS A USER-OVERRIDEABLE FUNCTION
        function onDisconnected() {
            Ui.requestUpdate();

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
