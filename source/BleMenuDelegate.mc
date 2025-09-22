using Toybox.WatchUi as Ui;
using Toybox.System;

class BleMenuDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        //Ui.MenuInputDelegate.initialize();
        Ui.BehaviorDelegate.initialize();
    }

    function onMenuItem(item) {
        if (item == :item_1) {
            System.println("item 1");
        } else if (item == :item_2) {
            System.println("item 2");
        }
    }

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), self, Ui.SLIDE_UP);
        return true;      
    }
}