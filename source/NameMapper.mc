using Toybox.System;
using Toybox.Lang;
//using Toybox.WatchUi as Ui; // to be removed later
using Toybox.Application.Storage as Stor;
using Toybox.Application.Properties as Prop;
import Toybox.Test;

using Toybox.WatchUi as Ui; // to be removed later

/* (2025-09-30)
 * this is a simple class to map thermometer broadcasted name
 * whcih includes 16 bits of adress / device id (eg "TH357 (40D2)"") to 
 * user friendly names (eg "Living Room").class 
 *
 * the ThermoInfo class holds the latest temperature/humidty of thermometer
 * and the selected flag states if it should be displayed.
 * 
 */


class ThermoInfo {
    public var key  as Lang.String; // the name broadcasted by thermometer
    public var name as Lang.String; // user friendly name
    public var selected as Lang.Boolean;
    public var lastTemperature;
    public var lastHumidity;

    function initialize(k,n,s) {
        self.key = k;
        self.name = n;
        self.selected = s;
        System.println("new ThermoInfo");
    }
    
    function setTemperature(t,h) as Void {
        self.lastTemperature = t;
        self.lastHumidity = h;
    }
}

/*
 * 2025-09-30
 * the NameMapper class holds a fixed number of ThermoInfo objects 
 * (num_thermo) which are initialized from properties stored in
 * persistent storage (see initialize() function).
 * This means that only that number of thermometers can be present 
 * when scanning (otherwise they are ignored).
 */

const num_thermo = 4;

class NameMapper  {
    protected var knownDevices  as  Lang.Array<ThermoInfo>;
    protected var iteratorIndex as Lang.Integer = 0;

    function initialize() {
        knownDevices =  new  Lang.Array<ThermoInfo>[num_thermo];
        for (var i=0; i<num_thermo; i++) {
            var kn = "th"+i+"_key";
            var k = Prop.getValue(kn);
            var n = "th"+i+"_name";
            var nm = Prop.getValue(n);
            n = "th"+i+"_usable";
            var s = Prop.getValue(n);
            if ((k == null)||(nm == null) /*|| nm.equals("")*/) {
                break;
            } 
            if (s==null) {
                s=true;
            } 
            var th = new ThermoInfo(k, nm, s);
            self.knownDevices[i] = th;
        }
    }


    function needsDisplay() {
        /*
         * (2025-09-30) unclear if throttling is done by
         * UI.requestUpdate() or if we need to do it here.
         *
         * design is a bit ugly here, as we include WatchUi
         * in this class, only for this function.
         * (we probably should move function to app class)
         */
        Ui.requestUpdate();
    }

    function getThermo(k)
    {
        for (var i=0; i<num_thermo; i++) {
            var th = knownDevices[i];
            if ((th == null) || (th.name == null) || (th.name.equals(""))) {
                break;
            }
            if (th.key.equals(k)) {
                return th;
            } 
        }
        return null;
    } 
    function thermoIteratorReset() {
        self.iteratorIndex = 0;
    }   
    function thermoIteratorNext() {
        for (;;) {
            if (self.iteratorIndex >= num_thermo) {
                return null;
            }
            var th = knownDevices[self.iteratorIndex];
            self.iteratorIndex++;
            if (th == null) {
                return null;
            }
            if ((th.selected==false) || (th.name==null) || (th.name.equals(""))) {
                continue;
            }
            return th;
        }
        return null;
    }
    function addThermo(k)
    {
        var iunsel = -1;
        for (var i = 0; i<num_thermo; i++) {
            var th = knownDevices[i];
            if ((th==null) || (th.name==null)) {
                th.key = k;
                th.name = k;
                th.selected = true;
                return th;
            }
            if (th.selected == false) {
                iunsel = i;
            }
        }
        // not found, try unselected
        if (iunsel >= 0) {
            var th = knownDevices[iunsel];
            th.key = k;
            th.name = k;
            th.selected = true;
            return th;
        }
        // cannot add
        return null;
    } 
    function setVal(k, temp, hum)
    {
        var th = getThermo(k);
        if (th == null) {
            th = addThermo(k);
            if (th == null) { return; }
        }
        th.setTemperature(temp, hum);
        System.println("th temp:"+th.lastTemperature);
        System.println("th temp:"+th.lastHumidity);
        if (th.selected) {
            self.needsDisplay();
        }
    } 
}


(:test)
function test1(logger as Logger) as Lang.Boolean {
    var m = new NameMapper();
    logger.debug("hop");
    m.setVal("toto", 25.0, 10);
    return true;
}
