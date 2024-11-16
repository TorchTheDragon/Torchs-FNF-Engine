package torchsthings.shaders;

import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.Assets;
import torchsfunctions.PostRuntimeShader;
import backend.MathUtil;

class CRT extends PostRuntimeShader {
    public var time(default, set):Float = 1;
    public var swipeAmount(default, set):Float = 4;
    public var creepyCRT(default, set):Float = 0.0;
    public var testStage(default, set):Float = 0.0;
    public var middle:Float = 0.5;

    public function new(?isCreepy:Bool = false, ?isTest:Bool = false) {
        var frag = Assets.getText(Paths.shaderFragment('CRT', 'torchs_assets'));
        super(frag);
        if (isCreepy) creepyCRT = 1;
        if (isTest) testStage = 1;
    }

    override function update(elapsed:Float):Void {
        if (testStage == 1) {
            this.setFloat('movingPoint', middle);
        }
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

    function set_creepyCRT(value:Float):Float {
        this.setFloat('uIsCreepy', value);
        return creepyCRT = value;
    }

    function set_testStage(value:Float):Float {
        this.setFloat('uIsTest', value);
        return testStage = value;
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