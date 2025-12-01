import Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
//using Toybox.BluetoothLowEnergy as Ble;
//using Toybox.Timer;
using Toybox.Lang;

//using Toybox.Cryptography as Crypto;




class TemperatureDatafield extends Ui.DataField
 {
    //private var namemapper;
    private var bled;
    function initialize(b as MyBleDelegate) {
        DataField.initialize();
        //namemapper = nm;
        self.bled = b;
    }

/*
    function timstr(){
        var t = System.getClockTime();
        var s = t.hour.format("%02d") + ":" 
            + t.min.format("%02d") + ":" 
            + t.sec.format("%02d");
        return s;
    }
*/


    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WidgetLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        System.println("TempWidgetView onShow() "+timstr());
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
       
        // Call the parent onUpdate function to redraw the layout
        DataField.onUpdate(dc);

        // update BLE state. clock tick is about once per second but does not
        // have to be exact.
        bled.tick();
        if (bled.valueUpdated() != true) {
            // no new data, skip redraw
            //return;
        }
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        if (h>50) {
            // display state
            var s = self.bled.msgstring();
            dc.drawText(5, h-16,
                    Graphics.FONT_TINY, s,
                    Graphics.TEXT_JUSTIFY_LEFT);
        }
        var wt = 0;
        var just = Graphics.TEXT_JUSTIFY_LEFT;
        if (w>160) {
            wt = 50;
        } else {
            wt = w/2;
            just = Graphics.TEXT_JUSTIFY_CENTER;
        }
        var tdeg = self.bled.temperature/10.0; // in 0.1 degC
       //tdeg = -123.4;
        var st = tdeg.format("%.1f")+" °C";
        dc.drawText(wt, h/2-10,
                    Graphics.FONT_LARGE, st,
                    just);
        if (w>110) {
            var fh = Graphics.FONT_SMALL;
            var hhum = self.bled.humidity; // in % RH
            var sh = hhum.format("%d")+" %RH";
            var wh = w - 20;
            var hh = h/2;
            if (w<200) {
                fh = Graphics.FONT_TINY;
                hh = 10;
                wh = w - 5;
            }
            dc.drawText(wh, hh,
                        fh, sh,
                        Graphics.TEXT_JUSTIFY_RIGHT);
        }

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
            System.println("TempWidgetView onHide() "+timstr());
    }

    // Handle menu item selection actually not called ?? (2025-09-29)
    function onMenuItem(item as  Lang.Symbol) as Void {
        if (item == "refresh") {
            // Handle refresh action
        } else if (item == "settings") {
            // Handle settings action
        }
    }
}
