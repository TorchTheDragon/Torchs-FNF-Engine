package states.stages;

import flixel.addons.effects.FlxTrail;
import states.stages.objects.*;
import shaders.WiggleEffectRuntime;
import substates.GameOverSubstate;
import cutscenes.DialogueBox;
import openfl.utils.Assets as OpenFlAssets;
import torchsthings.shaders.*;
import torchsfunctions.functions.ShaderUtils;
import openfl.filters.ShaderFilter;
import shaders.DropShadowShader;
import shaders.DropShadowScreenspace;

class SchoolEvilErect extends BaseStage
{
	var crt:CRT = new CRT(true);
	var shaderFilter:ShaderFilter;
	var wiggle:WiggleEffectRuntime;
	var bg:BGSprite;

	override function create()
	{
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
		
		var posX = 450;
		var posY = 400;

		bg = new BGSprite('weeb/erect/evilSchoolBG', posX, posY, 0.8, 0.9);
		bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bg.antialiasing = false;
		add(bg);
		setDefaultGF('gf-pixel');

		FlxG.sound.playMusic(playWeekMusic('LunchboxScary'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.8);
	}

	override function update(elapsed:Float)
	{
		if (ClientPrefs.data.shaders) {
		crt.update(elapsed);
		wiggle?.update(elapsed);
		}
	}
	override function createPost()
	{
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		addBehindDad(trail);
		var trail:FlxTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069);
		addBehindDad(trail);
		wiggle = new WiggleEffectRuntime(2, 4, 0.017, WiggleEffectType.DREAMY);
		bg.shader = wiggle;
		if (ClientPrefs.data.shaders) {
		shaderFilter = new ShaderFilter(crt);
		ShaderUtils.applyFiltersToCams([camGame],  [shaderFilter]);
		ShaderUtils.applyFiltersToCams([camHUD, camOther], [shaderFilter]);
		}
		applyShader(boyfriend, boyfriend.curCharacter);
		applyShader(gf, gf.curCharacter);
		applyShader(dad, dad.curCharacter);
	}

	// Ghouls event
	var bgGhouls:BGSprite;
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Trigger BG Ghouls":
				if(!ClientPrefs.data.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
		}
	}
	override function eventPushed(event:objects.Note.EventNote)
	{
		// used for preloading assets used on events
		switch(event.event)
		{
			case "Trigger BG Ghouls":
				if(!ClientPrefs.data.lowQuality)
				{
					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
					bgGhouls.updateHitbox();
					applyShader(bgGhouls, "");
	 				if (bgGhouls.shader != null && Std.isOfType(bgGhouls.shader, DropShadowShader)) {
            			cast(bgGhouls.shader, DropShadowShader).threshold = 0.1;
					}
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if(name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					addBehindGF(bgGhouls);
				}
		}
	}
	
	function applyShader(sprite:FlxSprite, char_name:String)
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-66, -10, 24, -23);
		rim.color = 0xFF641B1B;
		rim.antialiasAmt = 0;
		rim.attachedSprite = sprite;
		rim.distance = 5;
		switch (char_name)
		{
			case "bf-pixel":
				{
					rim.angle = 90;
					sprite.shader = rim;

					// rim.loadAltMask('assets/week6/images/weeb/erect/masks/bfPixel_mask.png');
					rim.altMaskImage = Paths.image("weeb/erect/masks/bfPixel_mask").bitmap;
					rim.maskThreshold = 1;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "pico-pixel":
				{
					rim.angle = 90;
					sprite.shader = rim;
					rim.altMaskImage = Paths.image("weeb/erect/masks/picoPixel_mask").bitmap;
					rim.maskThreshold = 1;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "gf-pixel":
				{
					rim.setAdjustColor(-42, -10, 5, -25);
					rim.angle = 90;
					sprite.shader = rim;
					rim.distance = 3;
					rim.threshold = 0.3;
					rim.altMaskImage = Paths.image("weeb/erect/masks/gfPixel_mask").bitmap;
					rim.maskThreshold = 1;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "nene-pixel":
				{
					rim.setAdjustColor(-42, -10, 5, -25);
					rim.angle = 90;
					sprite.shader = rim;
					rim.distance = 3;
					rim.threshold = 0.3;
					rim.altMaskImage = Paths.image("weeb/erect/masks/nenePixel_mask").bitmap;
					rim.useAltMask = true;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}

			case "spirit":
					{
						rim.angle = 90;
						sprite.shader = rim;
						rim.setAdjustColor(0, -10, 44, -13);
						rim.useAltMask = false;
	
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
			default:
				{
					rim.angle = 90;
					rim.threshold = 0.1;
					sprite.shader = rim;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
		}
	}
}