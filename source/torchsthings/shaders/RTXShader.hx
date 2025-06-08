package torchsthings.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.Assets;
import flixel.math.FlxAngle;
import objects.Character;

class RTXShader extends FlxRuntimeShader {
    public var overlayColor(default, set):FlxColor;
    public var satinColor(default, set):FlxColor;
    public var shadowColor(default, set):FlxColor;
    public var shadowAngle(default, set):Float = 0.0;
    public var shadowDistance(default, set):Float = 0.0;
    public var falloff(default, set):Bool = false;
    public var char:Character = null;
    public var defaultAngle:Float = 0.0;

    public function new(?character:Character = null) {
        var frag = Assets.getText(Paths.shaderFragment('RTX', 'torchs_assets'));
        super(frag);
        overlayColor = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 0.0);
        satinColor = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 0.0);
        shadowColor = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 0.0);
        shadowAngle = 0.0;
        defaultAngle = shadowAngle;
        shadowDistance = 0.0;
        falloff = false;
        if (character != null) char = character;
    }

    function set_overlayColor(val:FlxColor):FlxColor {
        this.setFloatArray('overlay', [val.redFloat, val.greenFloat, val.blueFloat, val.alphaFloat]);
        overlayColor = val;
        return val;
    }
    function set_satinColor(val:FlxColor):FlxColor {
        this.setFloatArray('satin', [val.redFloat, val.greenFloat, val.blueFloat, val.alphaFloat]);
        satinColor = val;
        return val;
    }
    function set_shadowColor(val:FlxColor):FlxColor {
        this.setFloatArray('shadow', [val.redFloat, val.greenFloat, val.blueFloat, val.alphaFloat]);
        shadowColor = val;
        if (shadowColor.alphaFloat < 0.45 && falloff == true && shadowDistance < 45.0) trace("Hey, I'd recommend changing your shadow colors alpha AND distance to be at least 0.45 if you are using falloff.");
        return val;
    }
    function set_shadowAngle(val:Float):Float {
        this.setFloat('daAngle', val * FlxAngle.TO_RAD);
        shadowAngle = val;
        return val;
    }
    function set_shadowDistance(val:Float):Float {
        this.setFloat('daDistance', val);
        shadowDistance = val;
        if (shadowColor.alphaFloat < 0.45 && falloff == true && shadowDistance < 45.0) trace("Hey, I'd recommend changing your shadow colors alpha AND distance to be at least 0.45 if you are using falloff.");
        return val;
    }
    function set_falloff(val:Bool):Bool {
        this.setFloat('falloffOn', val ? 1.0 : 0.0);
        falloff = val;
        if (shadowColor.alphaFloat < 0.45 && falloff == true && shadowDistance < 45.0) trace("Hey, I'd recommend changing your shadow colors alpha AND distance to be at least 0.45 if you are using falloff.");
        return val;
    }

    public function setShaderValues(?overlay:FlxColor, ?satin:FlxColor, ?shadow:FlxColor, ?angle:Float = 0.0, ?distance:Float = 0.0, ?fall:Bool = false) {
        if (overlay == null) overlay = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 1.0);
        if (satin == null) satin = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 1.0);
        if (shadow == null) shadow = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 1.0);
        overlayColor = overlay;
        satinColor = satin;
        shadowColor = shadow;
        shadowAngle = angle;
        defaultAngle = angle;
        shadowDistance = distance;
        falloff = fall;
        if (shadowColor.alphaFloat < 0.45 && falloff == true && shadowDistance < 45.0) trace("Hey, I'd recommend changing your shadow colors alpha AND distance to be at least 0.45 if you are using falloff.");
    }

    public function copyShader(?shade:RTXShader) {
        this.overlayColor = shade.overlayColor;
        this.satinColor = shade.satinColor;
        this.shadowColor = shade.shadowColor;
        this.shadowAngle = shade.shadowAngle;
        this.defaultAngle = shade.defaultAngle;
        this.shadowDistance = shade.shadowDistance;
        this.falloff = shade.falloff;
        if (this.shadowColor.alphaFloat < 0.45 && this.falloff == true && this.shadowDistance < 45.0) trace("Hey, I'd recommend changing your shadow colors alpha AND distance to be at least 0.45 if you are using falloff.");
    }

    public function update() {
        shadowAngle = defaultAngle - getAngle() - 90; // This is honestly so dumb but it's main purpose is for Nene... so... if it works, it works
    }
    
    function getAngle():Float {
        if (char != null && !char.isAnimateAtlas) {
            return char.frame.angle;
        } else return 0.0;
    }

    @:access(openfl.display.ShaderParameter)
    function addFloatUniform(name:String, length:Int):ShaderParameter<Float> {
        final res = new ShaderParameter<Float>();
        res.name = name;
        res.type = [null, FLOAT, FLOAT2, FLOAT3, FLOAT4][length];
        res.__arrayLength = 1;
        res.__isFloat = true;
        res.__isUniform = true;
        res.__length = length;
        __paramFloat.push(res);
        return res;
    }
}