package states.stages;

import states.stages.objects.*;
import flash.display.BlendMode;
import torchsthings.shaders.AdjustColorShader;
import cutscenes.CutsceneHandler;
import objects.Character;
import states.stages.cutscenes.CutsceneMallErect;


class MallErect extends BaseStage
{
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowdErect;
	public var santa:BGSprite;
	var blanked:BGSprite;
	var colorShader:AdjustColorShader;
	var blackScreen:FlxSprite;
	var cutsceneHandler:CutsceneHandler;
	var mallErectCutscene:CutsceneMallErect;

	override function create()
	{
		var bg:BGSprite = new BGSprite('christmas/erect/bgWalls', -1000, -500, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		add(bg);

		if(!ClientPrefs.data.lowQuality) {
			upperBoppers = new BGSprite('christmas/erect/upperBop', -240, -90, 0.33, 0.33, ['upperBop']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/erect/bgEscalator', -1100, -600, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);
		}

		var tree:BGSprite = new BGSprite('christmas/erect/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);
		
		blanked = new BGSprite('christmas/erect/white', -300, 40);
		blanked.scale.set(1.15, 1.15);
		blanked.updateHitbox();
		//blanked.alpha = 0.5;
		add(blanked);

		bottomBoppers = new MallCrowdErect(-300, 140);
		add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
		add(fgSnow);

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
		playWeekSound('Lights_Shut_off');
		setDefaultGF('gf-christmas');

		if (!isStoryMode && !seenCutscene)
		{
			if (PlayState.SONG.song.toLowerCase() == "eggnog")
			{
                setEndCallback(new CutsceneMallErect(this).eggnogErectCutscene);
			}
		}
	}

	override function createPost () 
	{
		boyfriend.shader = makecolorShader(-20,-15,0,-10);
		gf.shader = makecolorShader(-20,-15,0,-10);
		dad.shader = makecolorShader(-20,-15,0,-10);
		bottomBoppers.shader = makecolorShader(-4,-30,-22,0);
		santa.shader = makecolorShader(-20,-15,0,-10);
	}
	override function countdownTick(count:Countdown, num:Int) everyoneDance();
	override function beatHit() everyoneDance();

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Hey!":
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						return;
				}
		}
	}

	function everyoneDance()
	{
		if(!ClientPrefs.data.lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);
	}

	function eggnogEndCutscene()
	{
		if(PlayState.storyPlaylist[1] == null)
		{
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		if(nextSong == 'winter-horrorland')
		{
			FlxG.sound.play(playWeekSound('Lights_Shut_off'));

			var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
				-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			blackShit.scrollFactor.set();
			add(blackShit);
			camHUD.visible = false;

			inCutscene = true;
			canPause = false;

			new FlxTimer().start(1.5, function(tmr:FlxTimer) {
				endSong();
			});
		}
		else endSong();
	}
	public function makecolorShader(hue:Float,sat:Float,bright:Float,contrast:Float) {
        colorShader = new AdjustColorShader();
        colorShader.hue = hue;
        colorShader.saturation = sat;
        colorShader.brightness = bright;
        colorShader.contrast = contrast;
        return colorShader;
    }
}