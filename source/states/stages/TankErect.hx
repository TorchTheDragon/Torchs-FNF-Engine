package states.stages;

import backend.StageData;
import states.stages.objects.*;
import cutscenes.CutsceneHandler;
import shaders.DropShadowShader;
import shaders.DropShadowScreenspace;
import torchsthings.shaders.AdjustColorShader;
import flash.display.BlendMode;
import flixel.util.FlxSignal;
import objects.Character;
import states.stages.cutscenes.CutsceneTankErect;

class TankErect extends BaseStage
{
    
    var bg:BGSprite;
    var guy:FlxSprite;
    var sniper:FlxSprite;
    var tankmanRun:FlxTypedGroup<TankmenBG>;
	var tankmen:FlxSprite;
    var headtank:FlxSprite;
	var tankmenSpeaker:TankmenSpeaker;
    override function create()
    {
        bg = new BGSprite('Erect/bg', -1085, -805);
        bg.setGraphicSize(Std.int(bg.width * 1.15));
        bg.updateHitbox();
        add(bg);

        guy = new FlxSprite(1300, 410);
        guy.frames = Paths.getSparrowAtlas("Erect/guy");
        guy.setGraphicSize(Std.int(guy.width * 1.15));
        guy.updateHitbox();
        guy.animation.addByPrefix("idle", "BLTank2 instance 1", 24, false);
		guy.animation.play("idle");
        add(guy);

        sniper = new FlxSprite(-207, 339);
		sniper.frames = Paths.getSparrowAtlas("Erect/sniper");
		sniper.antialiasing = true;
		sniper.scale.set(1.15, 1.15);
		sniper.updateHitbox();
		sniper.animation.addByPrefix("idle", "Tankmanidlebaked instance 1", 24, false);
		sniper.animation.addByPrefix("sip", "tanksippingBaked instance 1", 24, false);
		sniper.animation.play("idle");
		add(sniper);

        tankmanRun = new FlxTypedGroup<TankmenBG>();
		add(tankmanRun);

		defaultSpeaker = 'abot';
        addSpeaker(gfGroup.x + 98, gfGroup.y + 351);

		if (!isStoryMode) //Lol
		{
			if (PlayState.SONG.song.toLowerCase() == "stress-pico-mix")
			{
				{
				setStartCallback(videoCutscene.bind('stressPicoCutscene'));
				}
                setEndCallback(new CutsceneTankErect(this).stressPicoCutscene);
			}
		}
    }	
    override function createPost()
    {
        super.createPost();

     if(!ClientPrefs.data.lowQuality) {
            for (daGf in gfGroup)
			{
                var gf:Character = cast daGf;
				if (gf.curCharacter == 'pico-speaker' || gf.curCharacter ==  'otis-speaker')
				{
					//GameOverSubstate.characterName = 'pico-holding-nene-dead';
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(30, 1900, true,false);
					firstTank.strumTime = 10;
					firstTank.visible = false;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length)
					{
						if (FlxG.random.bool(16))
						{
							var tankBih = tankmanRun.recycle(TankmenBG);
                            applyShader(tankBih, "");
                            if (tankBih.shader != null && Std.isOfType(tankBih.shader, DropShadowShader)) {
                            cast(tankBih.shader, DropShadowShader).threshold = 0.5;
                            }
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.scale.set(1.05, 1.05);
							tankBih.updateHitbox();
							tankBih.resetShit(600, 300, TankmenBG.animationNotes[i][1] < 2,false);
							// @:privateAccess
							// tankBih.endingOffset = 
							tankmanRun.add(tankBih);
						}
					}
					break;
				} 
				
            }
        }

        super.createPost();
		tankmenSpeaker = new TankmenSpeaker(speaker.tankmen, speaker.thugmen, this);
		addBehindDadAndBF(tankmenSpeaker);
        applyShader(boyfriend, boyfriend.curCharacter);
		applyShader(gf, gf.curCharacter);
		applyShader(dad, dad.curCharacter);
		//for the speaker lol
		var colorShader = new AdjustColorShader();
        colorShader.hue = -38;
        colorShader.saturation = -20;
        colorShader.contrast = -25;
        colorShader.brightness = -46;
		if (speaker != null) speaker.setShader(colorShader);

    }

	var videoEnded:Bool = false;
	function videoCutscene(?videoName:String = null)
	{
		game.inCutscene = true;
		if(!videoEnded && videoName != null)
		{
			#if VIDEOS_ALLOWED
			game.startVideo(videoName);
			game.videoCutscene.finishCallback = game.videoCutscene.onSkip = function()
			{
				videoEnded = true;
				game.videoCutscene = null;
            	game.inCutscene = false;
				startCountdown();
			};

			#else //Make a timer to prevent it from crashing due to sprites not being ready yet.
			new FlxTimer().start(0.0, function(tmr:FlxTimer)
			{
				videoEnded = true;
				game.inCutscene = false;
				startCountdown();
			});
			#end
			return;
		}
		
	}

    var isSipping:Bool = false;

    override function beatHit() {
        super.beatHit();
        if (!isSipping) {
            sniper.animation.play("idle", false);
        }
        guy.animation.play("idle", false);
		tankmenSpeaker.dance();
    
        if (!isSipping && FlxG.random.bool(2)) {  
            sipAnimation();
        }
    }
    
    function sipAnimation():Void {
        isSipping = true; 
        sniper.animation.play("sip", false, true);
    
        var timer = new FlxTimer();
        timer.start(3.48, function(_) {
            sniper.animation.play("idle", true, true);
            isSipping = false;
        });
    }
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		if(eventName == "Change Character" && ClientPrefs.data.shaders){
			switch(value1.toLowerCase().trim()) {
				case 'gf' | 'girlfriend' | '2':
					applyShader(gf, gf.curCharacter);
				case 'dad' | 'opponent' | '1':
					applyShader(dad, dad.curCharacter);
				default:
					applyShader(boyfriend, boyfriend.curCharacter);
			}
		}
	}
    function applyAbotShader(sprite:FlxSprite){
		var rim = new DropShadowScreenspace();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
        rim.threshold = 0.7;
		rim.antialiasAmt = 0;
		rim.attachedSprite = sprite;
		rim.angle = 90;
		sprite.shader = rim;
		sprite.animation.callback = function(anim, frame, index)
		{
			rim.updateFrameInfo(sprite.frame);
			rim.curZoom = camGame.zoom;
		};
	}
    function applyShader(sprite:FlxSprite, char_name:String)
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
		rim.threshold = 0.1;
		rim.attachedSprite = sprite;
		rim.distance = 15;
		rim.strength = 1;
		rim.angle = 90;
		switch (char_name)
		{
			case "bf":
				{
                    rim.angle = 90;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}

			case "nene":
				{
					rim.angle = 90;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
            case "tankman":
				{
					rim.threshold = 0.3;
					rim.angle = 90;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
            case "tankman-bloody":
				{
					rim.angle = 90;
					rim.altMaskImage = Paths.image("Erect/masks/tankmanCaptainBloody_mask").bitmap;
					rim.maskThreshold = 1;
					rim.threshold = 0.3;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			default:
				{
					rim.angle = 90;
					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
		}
		sprite.shader = rim;
	}
}