import Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Timer;
using Toybox.Lang;


//using Toybox.Cryptography as Crypto;


class TempWidgetView extends Ui.View {
     
    private var bled;


    function initialize(bleDelegate) {
        View.initialize();
        bled = bleDelegate;
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
        if ((1)) { return; }
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2,
                    Graphics.FONT_MEDIUM, self.bled.msgstring(),
                    Graphics.TEXT_JUSTIFY_CENTER);
    

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // Handle menu item selection
    function onMenuItem(item as  Lang.Symbol) as Void {
        if (item == "refresh") {
            // Handle refresh action
        } else if (item == "settings") {
            // Handle settings action
        }
    }
}
