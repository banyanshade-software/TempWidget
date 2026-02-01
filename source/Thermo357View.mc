using Toybox.Lang;
import Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;

const font_large = Graphics.FONT_SYSTEM_LARGE;
const font_small = Graphics.FONT_SYSTEM_SMALL;
const font_tiny = Graphics.FONT_SYSTEM_TINY;
const font_xtiny = Graphics.FONT_SYSTEM_XTINY;


class TemperatureDatafield extends Ui.DataField
 {
    private var bled;
    private var fontheight_large;
    private var fontheight_small;
    private var fontheight_tiny;
    private var fontheight_xtiny;

    private var width_temp;
    private var width_hum;

    private var fit as Thermo357Fit or Null;

    function initialize(b as MyBleDelegate) {
        DataField.initialize();
        self.bled = b;
        
        self.fit = new Thermo357Fit(self);

        // fontheight_large = Graphics.getFontAscent(font_large);
        fontheight_large = Graphics.getFontHeight(font_large);
        // see https://github.com/buessow/garmin/blob/6e1570fadb1e5057faed5a6fd4269eca87e59abe/GlucoseDataField/source/GlucoseDataFieldView.mc#L340

        fontheight_small = Graphics.getFontHeight(font_small);
        fontheight_tiny  = Graphics.getFontHeight(font_tiny);
        fontheight_xtiny  = Graphics.getFontHeight(font_xtiny);
    }



    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WidgetLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        debug_prt("TemperatureDatafield onShow()", null);
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


        /*
        calculate or update setup
        wide field :
          TEMP.  hum        TEMP hum
          state
        narrow field :
            hum         hum
            TEMP        TEMP       TEMP
            state

        */
        var w = dc.getWidth();
        var h = dc.getHeight();
        width_temp = dc.getTextWidthInPixels("-00.0 °C", font_large);
        width_hum = dc.getTextWidthInPixels("100 %RH", font_large);
        var disp_wide = false as Lang.Boolean;
        var disp_hum = false as Lang.Boolean;
        var disp_status = false as Lang.Boolean;
        var fh = fontheight_large;
        if ((width_temp+width_hum)*1.3 <= w) {
            disp_wide = true;
            disp_hum = true;
        } else {
            disp_wide = false;
            if (h >= (fontheight_large+font_small)*1.3) {
                disp_hum = true;
                fh += fontheight_small;
            } else {
                disp_hum = false;
            }
        }
        if (h>fh*1.2) {
            disp_status = true;
        } else {
            disp_status = false;
        }

        
        
        if (true) {
            // display temperature
            var valid = false;
            if (self.bled.valueAreValid()) {
                valid = true;
                fit.setTemperatureData(self.bled.temperature);
            }
            var tdeg = valid ? self.bled.temperature/10.0 : 0; // in 0.1 degC
            var st = (valid ? tdeg.format("%.1f") : "--") + "°C";

            if (!valid &&  bled.isFake()) {
                st = "No BLE";
            }
            if (valid && (tdeg < 3.0)) {
                dc.setColor(Graphics.COLOR_BLUE, bgcolor);
            }
            var x = w/10 + width_temp; 
            var y = h/10; // + fontheight_large;
            if (!disp_wide && disp_hum) {
                y += h/10 + fontheight_small;
            }

            dc.drawText(x, y, 
                    font_large, st,
                    Graphics.TEXT_JUSTIFY_RIGHT);
        }
    
        if (disp_status) {

        }
        return;
        /*
         * depending on field size, we will display mode below temperature
         * and humidity over temperature or on its right side
         * maller display will only show temperature
         *
         * Edge Explore 240x240
         *    half field : w=119 h=79 fhl=36 fhs=19 fht=17
         *    full field : w=240 h=79 fhl=36 fhs=19 fht=17
         */
        
        /*
        var hright = false;
        var hup = false;
        disp_status = true;

        if (w>width_temp+fontheight_small*5) {
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
                    font_tiny, s,
                    Graphics.TEXT_JUSTIFY_LEFT);
        }
        var valid = false;
        if (self.bled.valueAreValid()) {
            valid = true;
            fit.setTemperatureData(self.bled.temperature);
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
            var fhs = font_small;
            var hhum = valid ? self.bled.humidity : 0; // in % RH
            var sh = (valid ? hhum.format("%d") : "--" ) +" %RH";
            var wh = w - 20;
            var hh = h/2;
            if (w<200) {
                fhs = font_tiny;
                hh = fontheight_tiny;
                wh = w - 5;
            }
            dc.drawText(wh, hh,
                        fhs, sh,
                        Graphics.TEXT_JUSTIFY_RIGHT);
        }
        var tdeg = valid ? self.bled.temperature/10.0 : 0; // in 0.1 degC
        //tdeg = -18.1; // for test
        var st = (valid ? tdeg.format("%.1f") : "--") + "°C";
        if (!valid &&  bled.isFake()) {
            st = "No BLE"; 
        }
        if (valid && (tdeg < 3.0)) {
            dc.setColor(Graphics.COLOR_BLUE, bgcolor);
        }
        dc.drawText(wt, h/2-fontheight_large/2,
                    font_large, st,
                    just);
                    */
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        debug_prt("TemperatureDatafield onHide()", null);
    }

    // Handle menu item selection actually not called ?? (2025-09-29)
    function onMenuItem(item as  Lang.Symbol) as Void {
        if (item == "refresh") {
            // Handle refresh action
        } else if (item == "settings") {
            // Handle settings action
        }
    }



    function onNextMultisportLeg() {
    	fit.onNextMultisportLeg();
    }
    
    function onTimerLap() {
    	fit.onTimerLap();
    }
    
    function onTimerReset() {
    	fit.onTimerReset();
    }
    
    function onTimerPause() {
    	fit.onTimerPause();
    }
    
    function onTimerResume() {
    	fit.onTimerResume();
    }
    
    function onTimerStart() {
    	fit.onTimerStart();
    }
    
    function onTimerStop() {
    	fit.onTimerStop();
    }

}
