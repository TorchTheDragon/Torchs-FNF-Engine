package states.stages;

import states.stages.objects.*;

class Gray extends BaseStage {
    override function create() {
        var gray:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.GRAY);
        gray.updateHitbox();
        gray.centerOffsets();
        add(gray);
        /* 
            I still want a brighter screen than having a pure black screen for a default stage as some characters and icons 
            (like in psych mod songs that don't include stages) blend in too much to the background
        */
	}
}