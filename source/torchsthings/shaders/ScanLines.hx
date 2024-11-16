package torchsthings.shaders;

import openfl.display.BitmapData;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.Assets;
import torchsfunctions.PostRuntimeShader;

class ScanLines extends PostRuntimeShader {
    public var time(default, set):Float = 1;
    public var swipeAmount(default, set):Float = 4;

    public function new() {
        var frag = Assets.getText(Paths.shaderFragment('scanLines', 'torchs_assets'));
        super(frag);
    }

    override function update(elapsed:Float):Void {
        time += elapsed;
    }

    function set_time(value:Float):Float {
        this.setFloat('uTime', value);
        return time = value;
    }

    function set_swipeAmount(value:Float):Float {
        this.setFloat('uSwipeAmount', value);
        return swipeAmount = value;
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