package states.stages;

import states.stages.objects.*;
import flash.display.BlendMode;
import torchsthings.shaders.*;
import torchsthings.shaders.AdjustColorShader;


class StageErect extends BaseStage
{
    var crowd:BGSprite;
    var orange:BGSprite;

    // For the AdjustColorShader
    var colorShader:AdjustColorShader;

    override function create()
    {
        var bgblack:BGSprite = new BGSprite('erect/backDark', 510, -200);
        bgblack.setGraphicSize(Std.int(bgblack.width * 1.3));
        bgblack.updateHitbox();
        add(bgblack);

        crowd = new BGSprite('erect/crowd', 450, 250, ['Symbol 2 instance 1'], true);
        crowd.setGraphicSize(Std.int(crowd.width * 1.1));
        crowd.updateHitbox();
        add(crowd);

        orange = new BGSprite('erect/orangeLight', 50, -350);
        orange.setGraphicSize(Std.int(orange.width * 1.1));
        orange.updateHitbox();
        orange.blend = ADD;
        add(orange);

        var bg:BGSprite = new BGSprite('erect/bg', -800, -250);
        bg.setGraphicSize(Std.int(bg.width * 1.1));
        bg.updateHitbox();
        add(bg);

        var lightyellow:BGSprite = new BGSprite('erect/brightLightSmall', 920, -200);
        lightyellow.setGraphicSize(Std.int(lightyellow.width * 1.1));
        lightyellow.updateHitbox();
        lightyellow.blend = ADD;
        add(lightyellow);

        var light:BGSprite = new BGSprite('erect/lights', -800, -250);
        light.setGraphicSize(Std.int(light.width * 1.1));
        light.updateHitbox();
        add(light);

        var server:BGSprite = new BGSprite('erect/server', -500, 180);
        server.setGraphicSize(Std.int(server.width * 1.1));
        server.updateHitbox();
        add(server);
    }

    override function createPost()
    {
        super.createPost();
        gf.shader = makecolorShader(-9,0,-30,-4);
        dad.shader = makecolorShader(-32,0,-33,-23);
        boyfriend.shader = makecolorShader(12,0,-23,7);
    }
    function makecolorShader(hue:Float,sat:Float,bright:Float,contrast:Float) {
        colorShader = new AdjustColorShader();
        colorShader.hue = hue;
        colorShader.saturation = sat;
        colorShader.brightness = bright;
        colorShader.contrast = contrast;
        return colorShader;
    }
    function setShader(char:FlxSprite, charName:String)
	{
    	if (ClientPrefs.data.shaders) {
        	char.shader = colorShader;
    	} else {
        	char.shader = null;
    	}
	}
}