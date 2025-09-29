using Toybox.System;
using Toybox.Lang;
//using Toybox.WatchUi as Ui; // to be removed later
using Toybox.Application.Storage as Stor;
using Toybox.Application.Properties as Prop;
import Toybox.Test;

using Toybox.WatchUi as Ui; // to be removed later

class ThermoInfo {
    public var key  as Lang.String;
    public var name as Lang.String;
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
        if (self.iteratorIndex >= num_thermo) {
            return null;
        }
        var th = knownDevices[self.iteratorIndex];
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
