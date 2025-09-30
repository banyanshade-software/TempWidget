using Toybox.WatchUi as Ui;
using Toybox.System;

/*
 * (2025-09-29)
 * this is a simple leby delegate to exeperment menus
 * It is to be deleted later (probably) as we dont really need
 * a menu in this widget (all configuration, and specifically
 * thermometer renaming is done in mobile app ConnectIQ)
 */
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