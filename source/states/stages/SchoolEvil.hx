package states.stages;

import flixel.addons.effects.FlxTrail;
import states.stages.objects.*;
import substates.GameOverSubstate;
import cutscenes.DialogueBox;
import openfl.utils.Assets as OpenFlAssets;
import torchsfunctions.functions.ShaderUtils;
import torchsthings.shaders.GlitchEffect;
import torchsthings.shaders.CRT;
import torchsthings.objects.effects.ShadowEffect;
import openfl.filters.ShaderFilter;

class SchoolEvil extends BaseStage {
	var glitch:GlitchEffect;
	var gfGlitch:GlitchEffect;
	var backgroundGlitch:GlitchEffect;
	var glitchFilter:ShaderFilter;
	var crt:CRT;
	var crtFilter:ShaderFilter;

	override function create() {
		if (ClientPrefs.data.shaders) {
			crt = new CRT(true);

			if (ClientPrefs.data.intenseShaders) {
				glitch = new GlitchEffect(true, true, true, true, true, true, false);
				gfGlitch = new GlitchEffect(true, true, true, true, true, false, false);
				backgroundGlitch = new GlitchEffect(true, true, true, true, true, false, false);
				//glitch.invert = true;
				//backgroundGlitch.doTimer = false;
			}
			else {
				glitch = new GlitchEffect(true, false, false, false, true, false, false);
				gfGlitch = new GlitchEffect(true, false, false, false, true, false, false);
				//glitch.chromatic = false;
				//glitch.jitter = false;
				//glitch.wave = false;
				//glitch.scanlines = false;
				//glitch.chunkShift = false;
				//gfGlitch.chromatic = false;
				//gfGlitch.jitter = false;
				//gfGlitch.wave = false;
				//gfGlitch.scanlines = false;
				//gfGlitch.chunkShift = false;
			}
		}
		
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
		
		var posX = 400;
		var posY = 200;

		var bg:BGSprite;
		if(!ClientPrefs.data.lowQuality)
			bg = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
		else
			bg = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);

		bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bg.antialiasing = false;
		if (ClientPrefs.data.shaders && ClientPrefs.data.intenseShaders && backgroundGlitch != null) bg.shader = backgroundGlitch;
		add(bg);
		setDefaultGF('gf-pixel');

		FlxG.sound.playMusic(playWeekMusic('LunchboxScary'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.8);
		if(isStoryMode && !seenCutscene)
		{
			initDoof();
			setStartCallback(schoolIntro);
		}
	}
	override function createPost()
	{
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		addBehindDad(trail);
		if (ClientPrefs.data.shaders) {
			crtFilter = new ShaderFilter(crt);
			glitchFilter = new ShaderFilter(glitch);
			gf.shader = gfGlitch;
			ShaderUtils.applyFiltersToCams([camGame],  [glitchFilter, crtFilter]);
			ShaderUtils.applyFiltersToCams([camHUD], [crtFilter]);
		}
		
		var changePos:Float = 200;
		dad.cameras = boyfriend.cameras = [camHUD]; 
		dad.y -= changePos;
		trail.y -= changePos;
		dad.cameraPosition[1] += changePos;
		boyfriend.y -= changePos;
		boyfriend.cameraPosition[1] += changePos;
		
		var shadows1 = ShadowEffect.createShadows(dad, 0xFF3C6E, 200, 'spirit', 4, 0.25, -(changePos));
		PlayState.instance.shadowEffects.push(shadows1);
		for (shadow in shadows1) {
			addBehindDad(shadow);
		}
		var shadows2 = ShadowEffect.createShadows(boyfriend, 0x00F0FF, 200, 'boyfriend', 4, 0.25, -(changePos));
		PlayState.instance.shadowEffects.push(shadows2);
		for (shadow in shadows2) {
			addBehindBF(shadow);
		}
	}
	override function stepHit() {
		if (ClientPrefs.data.shaders) {
			if (curStep % 16 == 0) glitch.randomizeGlitches();
			if (curStep % 8 == 0) {
				gfGlitch.randomizeGlitches();
				if (backgroundGlitch != null && ClientPrefs.data.intenseShaders) backgroundGlitch.randomizeGlitches();
			}
		}
	}
	override function update(elapsed:Float) {
		if (ClientPrefs.data.shaders) {
			glitch.update(elapsed);
			gfGlitch.update(elapsed);
			if (backgroundGlitch != null && ClientPrefs.data.intenseShaders) backgroundGlitch.update(elapsed);
			
			crt.update(elapsed);
		}
	}

	// Ghouls event
	var bgGhouls:BGSprite;
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Trigger BG Ghouls":
				PlayState.instance.eventExisted = true;
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
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					if (ClientPrefs.data.shaders) bgGhouls.shader = gfGlitch;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if(name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					addBehindGF(bgGhouls);
				}
		}
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt('$songName/${songName}Dialogue_${ClientPrefs.data.language}'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			file = Paths.txt('$songName/${songName}Dialogue');
		}

		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			startCountdown();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}
	
	function schoolIntro():Void
	{
		inCutscene = true;
		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		add(red);

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;
		camHUD.visible = false;

		new FlxTimer().start(2.1, function(tmr:FlxTimer)
		{
			if (doof != null)
			{
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
				{
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
					{
						swagTimer.reset();
					}
					else
					{
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(playWeekSound('Senpai_Dies'), 1, false, null, true, function()
						{
							remove(senpaiEvil);
							senpaiEvil.destroy();
							remove(red);
							red.destroy();
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								add(doof);
								camHUD.visible = true;
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer)
						{
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});
			}
		});
	}
}