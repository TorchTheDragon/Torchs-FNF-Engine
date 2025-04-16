package torchsthings.utils;

import lime.app.Application;
import lime.ui.Window;
import flixel.util.typeLimit.*;
import torchsfunctions.WindowsBackend;

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
</target>
')
@:cppFileCode('
#include <Windows.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
')
#elseif linux
@:cppFileCode("#include <stdio.h>")
#end

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

    public static function bgColorAsTransparency(color:OneOfTwo<FlxColor, Array<Int>>, constUpdate:Bool = false) {
        // constUpdate is only intended for "update" function scenarios, which I honestly insist you don't use.
        #if cpp
        if (!transparencyDisabled) {
            if ((color is Array)) {
                var arr:Array<Int> = cast color;
                if (constUpdate) setWindowTransparency(arr[0], arr[1], arr[2], arr[3]);
                else WindowsBackend.setWindowTransparencyColor(arr[0], arr[1], arr[2], arr[3]);
            } else {
                // Assume it's a FlxColor, which is an Int abstract
                var bgColor:FlxColor = cast color;
                if (constUpdate) setWindowTransparency(bgColor.red, bgColor.green, bgColor.blue, bgColor.alpha);
                else WindowsBackend.setWindowTransparencyColor(bgColor.red, bgColor.green, bgColor.blue, bgColor.alpha);
            }
        } else trace("Transparency is disabled, I can't do shit!");
        #else
        trace('`bgColorAsTransparency` is not available on this platform!');
        #end
    }

    public static var transparencyDisabled:Bool = true;

    public static function disableTransparency(disable:Bool = true) {
        #if cpp
        if (disable) {
            WindowsBackend.disableWindowTransparency();
            transparencyDisabled = true;
        } else {
            transparencyDisabled = false;
        }
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

    // Custom Backend Stuff for Engine
    #if windows
    @:functionCode('
    HWND window = GetActiveWindow();

    int result = SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) | WS_EX_LAYERED);
    if (alpha > 255) alpha = 255;
    if (alpha < 0) alpha = 0;
    SetLayeredWindowAttributes(window, RGB(red, green, blue), alpha, LWA_COLORKEY | LWA_ALPHA);
    alpha = result;
    ')
    public static function setWindowTransparency(red:Int, green:Int, blue:Int, alpha:Int = 255) {return alpha;}
    #end
}