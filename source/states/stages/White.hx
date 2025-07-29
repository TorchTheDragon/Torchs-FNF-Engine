package states.stages;

import states.stages.objects.*;

class White extends BaseStage {
    override function create() {
        var white:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.WHITE);
        white.updateHitbox();
        white.centerOffsets();
        add(white);
	}
}