import Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
//using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Timer;
using Toybox.Lang;

//using Toybox.Cryptography as Crypto;


class TempWidgetView extends Ui.View {
     
    private var namemapper;

    function initialize(nm) {
        View.initialize();
        namemapper = nm;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WidgetLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        /*
         * (2025-09-30) all display fields are handled by layout.xml
         * so we just need to update the text fields here.
         */
        self.namemapper.thermoIteratorReset();
        for (var i=0; i<8; i++) {
            var n = "th" + i + "temp";
            var t = self.findDrawableById(n);
            if (t == null) {
                break;
            } 
            var th = self.namemapper.thermoIteratorNext();  
            if (th == null) {
                break;
            }
            var tht = th as ThermoInfo;
            var tt = t as Ui.Text;
            var temp = tht.lastTemperature;
            var hum = tht.lastHumidity;

            tt.setText("#"+i+" : "+temp+" °C");
            n = "th" + i + "hum";
            t = self.findDrawableById(n);
            tt = t as Ui.Text;
            tt.setText(hum+" %");
        }
        /* 2025-09-30 olds code to be removed (but we may need it as example)
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2,
                    Graphics.FONT_MEDIUM, self.bled.msgstring(),
                    Graphics.TEXT_JUSTIFY_CENTER);
        */

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
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
