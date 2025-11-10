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
    MODE_SCAN,           // scan for devices
    MODE_SCAN_LOW_SCAN,  // scan for devices every minutes
    MODE_SCAN_LOW_IDLE,
    MODE_CONNECTED
}

class MyBleDelegate extends Ble.BleDelegate {
    protected var namemapper;
    hidden var scanResults = [] as Lang.Array<Ble.ScanResult>;
    hidden var mode = MODE_NONE;
    hidden var device as Ble.Device or Null = null;
    //hidden var currentPacket;
    //hidden var connected = false;
    //hidden var scanning = false;
    //var nscan = 0;
    protected var t0 = 0;
    protected var tickValue = 0;
    var knownDevices = {};

    protected var charact_read  as Ble.Characteristic or Null;
    protected var charact_write as Ble.Characteristic or Null; 

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
        
        if ((0)) { // to be removed
            try {
                var t = Prop.getValue("k1");
                System.println("property k1: " + t);
                Prop.setValue("k1", "new k1 value"); 
                var t2 = Prop.getValue("k1");
                System.println("property k1 after set: " + t2);   
            } catch(ex) {
                System.println("exception " + ex);   

            } finally {

            }
        }
    }

    // callback function for the timer
    function tick() {
        //System.println("MyBleDelegate tick " + timstr());
        tickValue++;
        switch (mode) {
            case MODE_SCAN_LOW_SCAN:
                if (tickValue-t0 > 30) {
                    if (foundDevice()) {
                        System.println("TODO ");
                    } else {
                        Ble.setScanState(Ble.SCAN_STATE_OFF);
                        t0 = tickValue;
                        mode = MODE_SCAN_LOW_IDLE;
                    }
                }
                break;
            case MODE_SCAN_LOW_IDLE:
                if (tickValue-t0 > 120) {
                    Ble.setScanState(Ble.SCAN_STATE_SCANNING);
                    t0 = tickValue;
                    mode = MODE_SCAN_LOW_SCAN;
                }
                break;
            case MODE_SCAN:
                if (tickValue - t0 > 60) {
                    if (foundDevice()) {
                        System.println("TODO ");
                    } else {
                        Ble.setScanState(Ble.SCAN_STATE_OFF);
                        t0 = tickValue;
                        mode = MODE_SCAN_LOW_IDLE;
                    }
                }
                break;
            case MODE_NONE:
                System.println("should not happen"); 
                break;
            case MODE_CONNECTED:
                var k = false;
                if (self.device != null) {
                    k = self.device.isConnected();
                }
                if (k != false) {
                    System.println("device connected");
                }
                if ((0==t0) || (tickValue - t0 > 30)) {
                    System.println("update value ");
                    self.updateValues();
                    t0 = tickValue;
                }
                break;
            default:
                break;
        }
    }

    public function foundDevice() as Toybox.Lang.Boolean {
        if (self.scanResults.size() == 0) {
            return false;
        }
        // more check (vs selected device in config) to be added here
        return true;
    }
    function getFoundDevice() as Ble.ScanResult or Null {
        if (self.scanResults.size() == 0) {
            return null;
        }
        var d = self.scanResults[0] as Ble.ScanResult;
        return d;
    }   

    function needsDisplay() {
        Ui.requestUpdate();
    }
    /*
    function timerDone() {
        self.scanning = false;
        self.onScanFinished();
        self.needsDisplay();
    }
    */

    function startScanning() 
    {
        self.disconnect();
        self.scanResults = [];
        self.mode = MODE_SCAN;
        self.t0= tickValue;

        //registerMyProfile();

        Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        // scan for five seconds
        //timer.start(method(:timerDone), 5000, false);
        //self.mode = mode;
        //self.scanning = false;
    }

  
    function updateValues() {
        if (self.device != null /* && self.device.isConnected() */) {
            System.println("updating values from device " + self.device);
            // read TP357 temperature and humidity characteristics
            if ((charact_read == null) || (charact_write == null)) {
                System.println("cannot update, charact nil");
                return;
            }
            var payload = [ 0x01, 0x00, 0x00, 0x00 ]b as Lang.ByteArray; 
            charact_write.requestWrite(payload, {:writeType => Ble.WRITE_TYPE_DEFAULT});
            charact_read.requestRead();
        } else {
            System.println("cannot update values, not connected");
        }
    }   
    function msgstring() as Toybox.Lang.String {
        var s = "Mode: ";
        switch (self.mode) {
            case MODE_NONE:
                s += "NONE";
                break;
            case MODE_SCAN:
                s += "SCANNING";
                break;
            case MODE_SCAN_LOW_SCAN:
                s += "LOW SCANNING";
                break;
            case MODE_SCAN_LOW_IDLE:
                s += "LOW IDLE";
                break;
            case MODE_CONNECTED:
                if (self.device == null) {
                    s += "CONNECTED (no device)";
                    break;
                } else if (self.device.isConnected() == false) {
                    s += "CONNECTED (not connected)";
                    break;
                } else {
                    s += "PAIRED to " + self.device.getName();
                }
                break;
            default:
                s += "UNKNOWN";
                break;
        }
        return s;
    }

    /*
    function stopScanning() {
        self.disconnect();
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        // scan for five seconds
        //timer.start(method(:timerDone), 5000, false);
        //self.mode = mode;
        self.scanning = true;
    }
    */

    // helper function to see if a ScanResult has a specific service
    /*private function hasService(iterator, serviceUuid) {
        for (var uuid = iterator.next(); uuid != null; uuid = iterator.next()) {
            if (uuid.equals(serviceUuid)) {
                return true;
            }
        }
        return false;
    }*/

    // overrides the superclass - filters the results
    // https://github.com/pedasmith/BluetoothDeviceController/blob/6883b70da7852fa4c70dede47af628a72baff380/BluetoothDeviceController/Assets/CharacteristicsData/ThermoPro_TP357_Temperature.json#L4

    function onScanResults(iterator) {
        System.println("MyBleDelegate onScanResults "+timstr());
        var need = false;
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
                var add = true;
                for (var i = 0; i < self.scanResults.size(); i++) {
                    if (self.scanResults[i].isSameDevice(scanResult)) {
                        add = false;
                        break;
                    }
                }
                if (add) {
                    self.scanResults.add(scanResult);
                    if ((1)) { 
                        System.println(" new device, processing data:");
                        var raw = r.getRawData();
                        System.println("  raw data" + raw);
                        System.println("  len=" + raw.size());
                        // https://github.com/theengs/decoder/blob/development/src/devices/TPTH_json.h#L19-L25
                        var t = raw.decodeNumber(Toybox.Lang.NUMBER_FORMAT_SINT16, { :offset => 20,     :endianness => Toybox.Lang.ENDIAN_LITTLE });
                        var h = raw.decodeNumber(Toybox.Lang.NUMBER_FORMAT_UINT8,  { :offset => 20+2,   :endianness => Toybox.Lang.ENDIAN_LITTLE });
                        var f = raw.decodeNumber(Toybox.Lang.NUMBER_FORMAT_UINT8,  { :offset => 20+2+1, :endianness => Toybox.Lang.ENDIAN_LITTLE });
                        
                
                        System.println("  temp=" + t/10.0
                                    + "  hum=" + h
                                    + "  flag=" + f.format("%02X"));

                        /*
                        var th = self.namemapper.getThermo(n);
                        if (th != null) {
                            if (th.selected) {
                                System.println("  known device, updating "+timstr() );
                                self.connectToDevice(r);
                                self.namemapper.setVal(n, t/10.0, h);
                            }
                        }
                        self.namemapper.setVal(n, t/10.0, h);
                        need = true;
                        */
                    }
                    if (foundDevice()) {
                        Ble.setScanState(Ble.SCAN_STATE_OFF);
                        var fd = getFoundDevice() as Ble.ScanResult;
                        self.connectToDevice(fd);
                        self.mode = MODE_CONNECTED;
                        self.t0 = 0; // force update (tickValue;
                        System.println("-- connected -- ");
                        break;
                    }
                }
            }
        }
        if (need) {
            self.needsDisplay();
        } 
    }
            /*
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
            }*/
            /*
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
            
                if (cie == 0xCAC2) {
                    // unregistered ?? Thermopro

                }
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
        */
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
    //const DEVICE_NAME = "Bramator";
    //const SERVICE_UUID = "00001234-0000-1000-8000-00805F9B34FB";
    //const CHARACTERISTIC_UUID = "00005678-0000-1000-8000-00805F9B34FB";

    // common services uuids
    const SERV_UUID_GEN_DEVICE_INFO = "0000180A-0000-1000-8000-00805F9B34FB";
    const SERV_UUID_GEN_BATTERY      = "0000180F-0000-1000-8000-00805F9B34FB";
    // TP357 specific services uuids
    const SERV_UUID_TP357_PRIMARY = "00010203-0405-0607-0809-0a0b0c0d1910";
    const UUID_CHAR_TP357_READ    = "00010203-0405-0607-0809-0a0b0c0d2b10";
    const UUID_CHAR_TP357_WRITE   = "00010203-0405-0607-0809-0a0b0c0d2b11";
    // OTA according to https://github.com/pedasmith/BluetoothDeviceController/blob/6883b70da7852fa4c70dede47af628a72baff380/BluetoothDeviceController/Assets/CharacteristicsData/ThermoPro_TP357_Temperature.json#L29
    //const SERV_UUID_TP357_2       = "00010203-0405-0607-0809-0a0b0c0d1911";
    //const UUID_CHAR_TP357_2       = "00010203-0405-0607-0809-0a0b0c0d2b12";


    function registerMyProfile() {
            if ((0)) {
                Ble.registerProfile(
                {   :uuid => Ble.stringToUuid(SERV_UUID_GEN_DEVICE_INFO), // Device Information
                    :characteristics => [
                        { :uuid => Ble.stringToUuid("00002A29-0000-1000-8000-00805F9B34FB") }, // Manufacturer Name
                        { :uuid => Ble.stringToUuid("00002A24-0000-1000-8000-00805F9B34FB") }  // Model Number
                    ]
                });
                Ble.registerProfile({
                    :uuid => Ble.stringToUuid(SERV_UUID_GEN_BATTERY), // Battery Service
                    :characteristics => [
                        { :uuid => Ble.stringToUuid("00002A19-0000-1000-8000-00805F9B34FB") }  // Battery Level
                    ]  
                });
            }
           
            Ble.registerProfile({
                    :uuid => Ble.stringToUuid(SERV_UUID_TP357_PRIMARY), 
                    :characteristics => [
                        { :uuid => Ble.stringToUuid(UUID_CHAR_TP357_READ),
                          :descriptors => [ /*Ble.cccdUuid()*/ ] },
                        { :uuid => Ble.stringToUuid(UUID_CHAR_TP357_WRITE),
                          :descriptors => [] }
                    ]
                });
                /*Ble.registerProfile({
                    :uuid => Ble.stringToUuid(SERV_UUID_TP357_2), 
                    :characteristics => [
                        { :uuid => Ble.stringToUuid(UUID_CHAR_TP357_2),
                          :descriptors => [ Ble.cccdUuid() ] },
                      
                    ]
                });*/
            //Ble.registerProfile(profile); // onProfileRegister will be called on the delegate
            //var x = Ble.cccdUuid();
            //System.println("cccd uuid: " + x.toString() );
    }


    // pairs with the device at the specified index of the scan results
    function connectToDevice(dev as Ble.ScanResult) {
        // stop scanning
        Ble.setScanState(Ble.SCAN_STATE_OFF);
        self.disconnect();
        registerMyProfile();

        var d = Ble.pairDevice(dev);
        if (d == null) {
            System.println("pairDevice failed");
            return;
        } else {
            System.println("pairDevice succeeded "+d.isConnected());
        }
        self.device = d;
        dumpServices(d);
        getCharact(d);

/*
        var therder = d as Ble.Device;
        System.println("pairDevice returned " + therder);
        System.println("pairDevice returned " + therder.getName());
        //System.println("     bonded " + d.isBonded()); API 4.2.5
        System.println("     connected " + d.isConnected());
        System.println("     name " + d.getName());
        var s = d.getServices();
        System.println("     services " + s.toString());
        //System.println("     service # " + s.size());

        // iterater and print services
        for (var svcIter = s.next(); svcIter != null; svcIter = s.next()) {
            var service = svcIter as Ble.Service;
            System.println(" -- service: " + service.getUuid().toString());
            var charIter = service.getCharacteristics();
            for (var char = charIter.next(); char != null; char = charIter.next()) {
                var characteristic = char as Ble.Characteristic;
                System.println(" ---  characteristic: " + characteristic.getUuid().toString());
            }
        } 
        var s2 = dev.getServiceUuids();
        for (var svcIter = s2.next(); svcIter != null; svcIter = s2.next()) {
            var uuid = svcIter as Ble.Uuid;
            System.println(" -- service uuid: " + uuid.toString());
           
        } */
    
        self.needsDisplay();
    
    }

    // unpair the current device
    function disconnect() {
        if ((self.device != null) && (self.device.isConnected())) {
            Ble.unpairDevice(self.device);
            self.device = null;
            //self.connected = false;
            self.onDisconnected();
        }
        self.needsDisplay();
    }


    function dumpServices(device as Ble.Device) {
        System.println("dumpService");
        var s = device.getServices();
        for (var svcIter = s.next(); svcIter != null; svcIter = s.next()) {
            System.println("....... service XXXX");
            var service = svcIter as Ble.Service;
            System.println(" -- service: " + service.getUuid().toString());
            var charIter = service.getCharacteristics();
            for (var char = charIter.next(); char != null; char = charIter.next()) {
                var characteristic = char as Ble.Characteristic;
                System.println(" ---  characteristic: " + characteristic.getUuid().toString());
            }
        } 
    }

    function getCharact(device) as Void {
        var service = device.getService(Ble.stringToUuid(SERV_UUID_TP357_PRIMARY));
        if (service == null) {
            System.println("no primary service: ");
            return;
        }
        System.println("service: " + service.toString());
        var chUUID = Ble.stringToUuid(UUID_CHAR_TP357_READ);
        charact_read = service.getCharacteristic(chUUID);
        System.println("characteristic R : " + charact_read);
        chUUID = Ble.stringToUuid(UUID_CHAR_TP357_WRITE);
        charact_write = service.getCharacteristic(chUUID);
        System.println("characteristic W: " + charact_write);
    }

    // callback function for the BLE delegate (overrides superclass)
    function onConnectedStateChanged(device, state) {
        System.println("MyBleDelegate onConnectedStateChanged  state="+state);
        dumpServices(device);
        if ((1)) {
            getCharact(device);
        }
       
        // if connected, send connection info to the network manager
        if (state == Ble.CONNECTION_STATE_CONNECTED && device != null) {
            System.println("talallalala connected XXXX");
            self.device = device;
            // iterater and print services
            var s = device.getServices();
            for (var svcIter = s.next(); svcIter != null; svcIter = s.next()) {
                System.println("....... service XXXX");
                var service = svcIter as Ble.Service;
                System.println(" -- service: " + service.getUuid().toString());
                var charIter = service.getCharacteristics();
                for (var char = charIter.next(); char != null; char = charIter.next()) {
                    var characteristic = char as Ble.Characteristic;
                    System.println(" ---  characteristic: " + characteristic.getUuid().toString());
                }
            } 
            //var s = self.device.getServices();
            
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
            /*
        } else {  // clear the connection parameters
            if (device != null) {
                Ble.unpairDevice(device);
            }
            self.device = null;
            self.connected = false;
            //self.networkManager.setCharacteristics(null, null);
            self.onDisconnected();
            */
        }
        self.needsDisplay();

    }

    // callback function from the BLE Delegate. Accepts data, figures out what to do with it
    function onCharacteristicChanged(characteristic, value) {
        System.println(" onCharacteristicChanged  characteristic: " + characteristic.getUuid().toString());
        System.println("                          value : " + value);
        //if (characteristic.getUuid().equals(PROXY_SERVICE_OUT) || characteristic.getUuid().equals(PROVISION_SERVICE_OUT)) {
        //    self.networkManager.processProxyData(value);
        //}
    }
    function onCharacteristicRead(characteristic as Ble.Characteristic, 
                                  status as Ble.Status, value as Lang.ByteArray) as Void
    {
        System.println(" onCharacteristicRead  characteristic: " + characteristic.getUuid().toString());
        System.println("                          value : " + value);

    }
/*
    function isConnected() {
        return self.connected;
    }

    function isScanning() {
        return self.scanning;
    }
*/
    // clears all known data of the mesh network
    //function deleteAllData() {
        /*
        self.networkManager.keyManager.clearKeys();
        self.networkManager.deviceManager.reset();
        self.networkManager.provisioningManager.reset();
        self.networkManager.save();
        */
    //}


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
