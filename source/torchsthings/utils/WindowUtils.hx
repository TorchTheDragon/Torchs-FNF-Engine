package torchsthings.utils;

import lime.app.Application;
import lime.ui.Window;
import flixel.util.typeLimit.*;

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

bool transparencyEnabled = false;
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
        setColorMode(isDark);
        isDarkMode = isDark;
        #else
        trace('`setWindowColorMode` is not available on this platform!');
        #end
    }

    public static function setDarkMode() {
        #if cpp
        setColorMode(true);
        isDarkMode = true;
        #else 
        trace('`setDarkMode` is not available on this platform!');
        #end
    }

    public static function setLightMode() {
        #if cpp
        setColorMode(false);
        isDarkMode = false;
        #else 
        trace('`setLightMode` is not available on this platform!');
        #end
    }

    public static function setWindowBorderColor(color:Array<Int>, setHeader:Bool = true, setBorder:Bool = true) {
        #if cpp
        setBorderColor(((color != null) ? color : [255, 255, 255]), setHeader, setBorder);
        if(setHeader) windowHeaderColor = ((color != null) ? color : [255, 255, 255]);
        if(setBorder) windowBorderColor = ((color != null) ? color : [255, 255, 255]);
        #else
        trace('`setWindowBorderColor` is not available on this platform!');
        #end
    }

    public static function setWindowTitleColor(color:Array<Int>) {
        #if cpp
        setTitleColor(((color != null) ? color : [255, 255, 255]));
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



    // Everything down here is just backend stuff
    #if windows
    @:functionCode('
        HWND window = GetActiveWindow();
        int isDark = (isDarkMode ? 1 : 0);
    
        if (DwmSetWindowAttribute(window, 19, &isDark, sizeof(isDark)) != S_OK) {
            DwmSetWindowAttribute(window, 20, &isDark, sizeof(isDark));
        }
        UpdateWindow(window);
    ')
    static function setColorMode(isDarkMode:Bool) {}
    
    @:functionCode('
        HWND window = GetActiveWindow();
        auto finalColor = RGB(color[0], color[1], color[2]);
    
        if(setHeader) DwmSetWindowAttribute(window, 35, &finalColor, sizeof(COLORREF));
        if(setBorder) DwmSetWindowAttribute(window, 34, &finalColor, sizeof(COLORREF));
    
            UpdateWindow(window);
    ')
    static function setBorderColor(color:Array<Int>, setHeader:Bool = true, setBorder:Bool = false) {}
    
    @:functionCode('
        HWND window = GetActiveWindow();
        auto finalColor = RGB(color[0], color[1], color[2]);
    
        DwmSetWindowAttribute(window, 36, &finalColor, sizeof(COLORREF));
        UpdateWindow(window);
    ')
    static function setTitleColor(color:Array<Int>) {}
    
    @:functionCode('UpdateWindow(GetActiveWindow());')
    static function updateWindow() {}
    #end
}