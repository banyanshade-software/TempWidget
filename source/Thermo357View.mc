using Toybox.Lang;
import Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;




class TemperatureDatafield extends Ui.DataField
 {
    private var bled;
    private var fontheight_large;
    private var fontheight_small;
    private var fontheight_tiny;
    private var temp_width;

    function initialize(b as MyBleDelegate) {
        DataField.initialize();
        self.bled = b;
        //fontheight_large = Graphics.getFontAscent(Graphics.FONT_LARGE);
        fontheight_large = Graphics.getFontHeight(Graphics.FONT_LARGE);
        fontheight_small = Graphics.getFontHeight(Graphics.FONT_SMALL);
        fontheight_tiny  = Graphics.getFontHeight(Graphics.FONT_TINY);
    }



    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WidgetLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        System.println("TemperatureDatafield onShow() "+timstr());
        self.bled.forceRefresh();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        DataField.onUpdate(dc);

        var bgcolor = getBackgroundColor();
        var fgcolor = Graphics.COLOR_WHITE;
        if (bgcolor == Graphics.COLOR_WHITE) {
            // light mode
            fgcolor = Graphics.COLOR_BLACK;
        }

        // update BLE state. clock tick is about once per second but does not
        // have to be exact.
        bled.tick();
       
        dc.setColor(fgcolor, bgcolor);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        temp_width = dc.getTextWidthInPixels("-00.0 °C", Graphics.FONT_LARGE);

        if ((false)) {
            System.println("TemperatureDatafield onUpdate() w="
                +w.format("%d")+" h="+h.format("%d")
                +" fhl="+fontheight_large.format("%d")
                +" twidth="+temp_width.format("%d")
                +" fhs="+fontheight_small.format("%d")
                +" fht="+fontheight_tiny.format("%d")
                );
        }
        /*
         * depending on field size, we will display mode below temperature
         * and humidity over temperature or on its right side
         * maller display will only show temperature
         *
         * Edge Explore 240x240
         *    half field : w=119 h=79 fhl=36 fhs=19 fht=17
         *    full field : w=240 h=79 fhl=36 fhs=19 fht=17
         */
        
        var hright = false;
        var hup = false;
        var disp_status = true;

        if (w>temp_width+fontheight_small*5) {
            // we assume that fontheiught_small*5 is enought space for humidity
            // and avoid calculating real width
            hright = true;
        } else if (h>fontheight_large+fontheight_tiny*2) {
            hup = true;
        } else if (h>fontheight_large+fontheight_tiny*1) {
            hup = true;
            disp_status = false;
        } else {
            disp_status = false;
        }
        if (disp_status) {
            // display state for debugging
            //it should be changed to something user friendly later
            var s = self.bled.msgstring();
            dc.drawText(5, h-fontheight_tiny-1,
                    Graphics.FONT_TINY, s,
                    Graphics.TEXT_JUSTIFY_LEFT);
        }
        var valid = false;
        if (self.bled.valueAreValid()) {
            valid = true;
        }
        var wt = 0;
        var just = Graphics.TEXT_JUSTIFY_LEFT;
        if (w>160) {
            wt = 50;
        } else {
            wt = w/2;
            just = Graphics.TEXT_JUSTIFY_CENTER;
        }
      
        if (w>110) {
            var fh = Graphics.FONT_SMALL;
            var hhum = valid ? self.bled.humidity : 0; // in % RH
            var sh = (valid ? hhum.format("%d") : "--" ) +" %RH";
            var wh = w - 20;
            var hh = h/2;
            if (w<200) {
                fh = Graphics.FONT_TINY;
                hh = fontheight_tiny;
                wh = w - 5;
            }
            dc.drawText(wh, hh,
                        fh, sh,
                        Graphics.TEXT_JUSTIFY_RIGHT);
        }
        var tdeg = valid ? self.bled.temperature/10.0 : 0; // in 0.1 degC
        //tdeg = -18.1; // for test
        var st = (valid ? tdeg.format("%.1f") : "--") +" °C";
        if (!valid &&  bled.isFake()) {
            st = "No BLE"; 
        }
        if (valid && (tdeg < 3.0)) {
            dc.setColor(Graphics.COLOR_BLUE, bgcolor);
        }
        dc.drawText(wt, h/2-fontheight_large/2,
                    Graphics.FONT_LARGE, st,
                    just);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
            System.println("TemperatureDatafield onHide() "+timstr());
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
