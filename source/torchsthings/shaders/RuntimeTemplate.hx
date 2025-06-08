package torchsthings.shaders;

import lime.utils.Assets;
import flixel.addons.display.FlxRuntimeShader;

class RuntimeTemplate extends FlxRuntimeShader {
    public function new() {
        super(Assets.getText(Paths.shaderFragment('name of frag file', 'library of frag file')));
    }

    /*
    // These are just here to show how to edit the variables in the shader
    public var basicFloat(default, set):Float = 0.0;
    function set_basicFloat(value:Float):Float {
        this.setFloat('floatVar', value);
        return basicFloat = value;
    }
    */

    /*
    // This function is only here for is you have uniform time variables in the shader
    var time:Float = 0.0;
    public function update(elapsed:Float) {
        time += elapsed;
        setFloat("iTime", time);
    }
    */
}