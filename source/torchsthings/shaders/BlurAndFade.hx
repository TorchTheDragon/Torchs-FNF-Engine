package torchsthings.shaders;

import lime.utils.Assets;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxColor;

class BlurAndFade extends FlxRuntimeShader {
    public var blurAmount(default, set):Float;
    public var edgeFade(default, set):Float;
    var parent:FlxSprite = null;

    public function new(parent:FlxSprite, ?blurAmount:Float = 2.5, ?edgeFade:Float = 0.5, ?instanceID:String = '') {
        var source = Assets.getText(Paths.shaderFragment('BlurAndFade', 'torchs_assets'));
        source += "\n#define INSTANCE_ID_" + ((instanceID != null && instanceID != '') ? instanceID : Std.string(Std.random(999))); // This makes sure you can have MULTIPLE of this effect if you want
        super(source);
        this.parent = parent;
        this.blurAmount = blurAmount;
        this.edgeFade = edgeFade;
    }

    public function syncFrameUVs():Void {
        if (parent == null || parent.frame == null) return;

        var texW = parent.pixels.width;
        var texH = parent.pixels.height;
        var rect = parent.frame.frame;

        this.setFloatArray('framePos', [rect.x / texW, rect.y / texH]);
        this.setFloatArray("frameSize", [rect.width / texW, rect.height / texH]);

        var col:FlxColor = parent.color;
        this.setFloatArray('tintColor', [col.redFloat, col.greenFloat, col.blueFloat, col.alphaFloat]);
    }

    function set_blurAmount(value:Float):Float {
        this.setFloat('blurAmount', value);
        blurAmount = value;
        return blurAmount;
    }
    function set_edgeFade(value:Float):Float {
        this.setFloat('edgeFade', value);
        edgeFade = value;
        return edgeFade;
    }
}