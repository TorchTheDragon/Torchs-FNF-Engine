package torchsthings.shaders;

import openfl.display.BitmapData;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.Assets;
import torchsfunctions.PostRuntimeShader;

// Copied from WeekEnd update for FNF
class Rain extends PostRuntimeShader {
    static final MAX_LIGHTS:Int = 8;

    public var time(default, set):Float = 1;
    public var scale(default, set):Float = 1;
    public var intensity(default, set):Float = 0.4;
    // Only useful for actually changing the intensity throughout the song
    public var lerpIntensity:Bool = false;
    public var intensityStart:Float = 0;
    public var intensityEnd:Float = 0.5;
    public var lerpRatio:Float = 0;

    public function new() {
        var frag = Assets.getText(Paths.shaderFragment('rain', 'torchs_assets'));
        super(frag);
        setDefaults();
    }

    public function setDefaults() {
        scale = FlxG.height / 200;
        intensity = 0.4;
        updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
    }

    public function setIntenseValues(start:Float = 0, end:Float = 0.5) {
        lerpIntensity = true;
        intensityStart = start;
        intensityEnd = end;
    }

    override function update(elapsed:Float):Void {
        if (lerpIntensity == true) {intensity = FlxMath.lerp(intensityStart, intensityEnd, lerpRatio);}
        time += elapsed;
    }

    function set_time(value:Float):Float {
        this.setFloat('uTime', value);
        return time = value;
    }

    function set_scale(value:Float):Float {
        this.setFloat('uScale', value);
        return scale = value;
    }

    function set_intensity(value:Float):Float {
        this.setFloat('uIntensity', value);
        return intensity = value;
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