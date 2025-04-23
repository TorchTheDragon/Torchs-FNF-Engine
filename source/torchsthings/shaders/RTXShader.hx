package torchsthings.shaders;

//import torchsfunctions.PostRuntimeShader;
import flixel.addons.display.FlxRuntimeShader;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.Assets;
import flixel.math.FlxAngle;

class RTXShader extends FlxRuntimeShader {
    public var overlayColor(default, set):FlxColor;
    public var satinColor(default, set):FlxColor;
    public var shadowColor(default, set):FlxColor;
    public var shadowAngle(default, set):Float = 0.0;
    public var shadowDistance(default, set):Float = 0.0;

    public function new() {
        var frag = Assets.getText(Paths.shaderFragment('RTX', 'torchs_assets'));
        super(frag);
        overlayColor = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 0.0);
        satinColor = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 0.0);
        shadowColor = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 0.0);
        shadowAngle = 0.0;
        shadowDistance = 0.0;
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
        return val;
    }

    public function setShaderValues(?overlay:FlxColor, ?satin:FlxColor, ?shadow:FlxColor, ?angle:Float = 0.0, ?distance:Float = 0.0) {
        if (overlay == null) overlay = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 1.0);
        if (satin == null) satin = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 1.0);
        if (shadow == null) shadow = FlxColor.fromRGBFloat(0.0, 0.0, 0.0, 1.0);
        overlayColor = overlay;
        satinColor = satin;
        shadowColor = shadow;
        shadowAngle = angle;
        shadowDistance = distance;
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