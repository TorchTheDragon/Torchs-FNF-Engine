package torchsthings.utils;

import lime.app.Application;
import lime.ui.Window;
import flixel.util.typeLimit.*;
import torchsfunctions.WindowsBackend;

class WindowUtils {
    public static var gameWindow(get, default):Window = null;
    static function get_gameWindow() {
        return Application.current.window;
    }
    public static var baseTitle:String = "Friday Night Funkin': Torch Engine";
    public static final DEFAULT_TITLE:String = "Friday Night Funkin': Torch Engine";
    public static var isDarkMode:Bool = false;
    public static var windowHeaderColor:Array<Int> = [];
    public static var windowBorderColor:Array<Int> = [];
    public static var windowTitleColor:Array<Int> = [];

    public static function setWindowColorMode(isDark:Bool = true) {
        #if cpp
        WindowsBackend.setColorMode(isDark);
        isDarkMode = isDark;
        #else
        trace('`setWindowColorMode` is not available on this platform!');
        #end
    }

    public static function setDarkMode() {
        #if cpp
        WindowsBackend.setColorMode(true);
        isDarkMode = true;
        #else 
        trace('`setDarkMode` is not available on this platform!');
        #end
    }

    public static function setLightMode() {
        #if cpp
        WindowsBackend.setColorMode(false);
        isDarkMode = false;
        #else 
        trace('`setLightMode` is not available on this platform!');
        #end
    }

    public static function bgColorAsTransparency(color:OneOfTwo<FlxColor, Array<Int>>) {
        #if cpp
        if ((color is Array)) {
            var arr:Array<Int> = cast color;
            WindowsBackend.setWindowTransparencyColor(arr[0], arr[1], arr[2], arr[3]);
        } else {
            // Assume it's a FlxColor, which is an Int abstract
            var bgColor:FlxColor = cast color;
            WindowsBackend.setWindowTransparencyColor(bgColor.red, bgColor.green, bgColor.blue, bgColor.alpha);
        }
        #else
        trace('`bgColorAsTransparency` is not available on this platform!');
        #end
    }

    public static function disableTransparency() {
        #if cpp
        WindowsBackend.disableWindowTransparency();
        #else
        trace('`disableTransparency` is not available on this platform!');
        #end
    }

    public static function setWindowBorderColor(color:Array<Int>, setHeader:Bool = true, setBorder:Bool = true) {
        #if cpp
        WindowsBackend.setBorderColor(((color != null) ? color : [255, 255, 255]), setHeader, setBorder);
        if(setHeader) windowHeaderColor = ((color != null) ? color : [255, 255, 255]);
        if(setBorder) windowBorderColor = ((color != null) ? color : [255, 255, 255]);
        #else
        trace('`setWindowBorderColor` is not available on this platform!');
        #end
    }

    public static function setWindowTitleColor(color:Array<Int>) {
        #if cpp
        WindowsBackend.setTitleColor(((color != null) ? color : [255, 255, 255]));
        windowTitleColor = ((color != null) ? color : [255, 255, 255]);
        #else
        trace('`setWindowTitleColor` is not available on this platform!');
        #end
    }

    public static function redrawWindowHeader() {
        gameWindow.borderless = true;
        gameWindow.borderless = false;
    }

    public static function changeTitle(title:String) {
        gameWindow.title = title;
    }
    public static function changeDefaultTitle(title:String, ?changeNow:Bool = false) {
        baseTitle = title;
        if (changeNow) changeTitle(title);
    }
    public static function getCurrentTitle():String {
        return gameWindow.title;
    }
}