package torchsthings.objects;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.typeLimit.*;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end
import torchsfunctions.functions.MathTools;
import states.stages.objects.ABotSpeaker;
import torchsthings.objects.speakers.*;
import objects.Character;

class SpeakerSkin extends FlxSpriteGroup {
    public var spriteList:Array<String> = [ // Speakers based on FlxSprite
        'base',
        'base-christmas'
    ];
    #if flxanimate
    public var atlasList:Array<String> = [ // Speakers based on FlxAnimate
        'base-altas'
    ];
    #end
    public var customSpeakerList:Array<String> = [
        'abot',
        'nene',
        'abot-pixel',
        'nene-pixel'
    ];
    public var gf:Character = PlayState.instance.gf;
    public var bpm:Float = PlayState.SONG.bpm;

    public var atlasSpeaker:FlxAnimate;
    public var spriteSpeaker:FlxSprite;

    var customSpeaker:Bool = false; // This is for use with completely unique speakers, like Nene's for example
    public var daCustomSpeaker:Dynamic = null;

    override public function new(x:Float, y:Float, speaker:String = 'base', ?custom:Bool = false, ?nameOfCustom:String = 'nene') {
        super(x,y);
        var speakerSettings:SpeakerSettings = null;
        if (Paths.fileExists('speakerskins/$speaker', TEXT, false, 'shared')) {
            haxe.Json.parse(Assets.getText(Paths.json('speakerskins/' + speaker))); // I think I'd prefer this to be in the data folder just so that we can have atlas skins in the speakerskins folder as well
        } else {
            speakerSettings = {
                beatAnim: 'speakers',
                isAnimateAtlas: false
            }
        }
        if (speakerSettings.library == null || speakerSettings.library == '') speakerSettings.library = 'shared';
        if (speakerSettings.offsets == null) speakerSettings.offsets = [0, 0];
        if (speakerSettings.gfOffsets == null) speakerSettings.gfOffsets = [0, 0];

        if (custom == true && customSpeakerList.contains(nameOfCustom.toLowerCase())) {
            customSpeaker = true;
            switch (nameOfCustom.toLowerCase()) {
                case 'abot' | 'nene':
                    daCustomSpeaker = new ABotSpeaker();
                    updateABotEye(daCustomSpeaker, true);
                case 'abot-pixel' | 'nene-pixel':
                    daCustomSpeaker = new PixelABot();
                    //daCustomSpeaker.scale.set(6, 6);
                    updateABotEye(daCustomSpeaker, true);
            }
            if (daCustomSpeaker != null) add(daCustomSpeaker);
        } else if (!spriteList.contains(speaker) #if flxanimate && !atlasList.contains(speaker) #end) {
            spriteSpeaker = new FlxSprite().loadGraphic(Paths.image('speakerskins/base'), true);
            spriteSpeaker.frames = Paths.getSparrowAtlas('speakerskins/base');
            spriteSpeaker.animation.addByPrefix('boom', 'speakers', 24, false);
            spriteSpeaker.animation.play('boom', true);
        } else if (spriteList.contains(speaker) #if flxanimate && !speakerSettings.isAnimateAtlas #end) {
            spriteSpeaker = new FlxSprite().loadGraphic(Paths.image('speakerskins/$speaker', speakerSettings.library), true);
            spriteSpeaker.frames = Paths.getSparrowAtlas('speakerskins/$speaker', speakerSettings.library);
            spriteSpeaker.animation.addByPrefix('boom', speakerSettings.beatAnim, 24, false);
            spriteSpeaker.animation.play('boom', true);
        } #if flxanimate else if (atlasList.contains(speaker) && speakerSettings.isAnimateAtlas) {
            atlasSpeaker = new FlxAnimate();
            atlasSpeaker.showPivot = false;
            Paths.loadAnimateAtlasFromLibrary(atlasSpeaker, 'speakerskins/$speaker', speakerSettings.library);
            atlasSpeaker.anim.addBySymbol('boom', speakerSettings.beatAnim, 24, false);
            atlasSpeaker.anim.play('boom', true);
        } #end else {
            trace('How in the world did you manage to not make a speaker here? I even set up a failsafe...');
        }

        if (!customSpeaker) {
            if (atlasSpeaker != null) {
                atlasSpeaker.antialiasing = ClientPrefs.data.antialiasing;
                add(atlasSpeaker);
            } else if (spriteSpeaker != null) {
                spriteSpeaker.antialiasing = ClientPrefs.data.antialiasing;
                add(spriteSpeaker);
            }
        }
    }

    public function updateABotEye(?abot:Dynamic, ?finishInstantly:Bool = false) {
		if (abot != null && (abot is ABotSpeaker || abot is PixelABot)) {
            var lookAtPlayer:Bool = PlayState.SONG.notes[Std.int(FlxMath.bound(PlayState.instance.curSection, 0, PlayState.SONG.notes.length - 1))].mustHitSection;

			if(lookAtPlayer)
				abot.lookRight();
			else
				abot.lookLeft();
	
			if(finishInstantly) {
                if (abot is ABotSpeaker) abot.eyes.anim.curFrame = abot.eyes.anim.length - 1;
                else if (abot is PixelABot) lookAtPlayer ? abot.abotHead.animation.play('right') : abot.abotHead.animation.play('left');
            }
		}
	}

	var volumes:Array<Float> = [];
    #if funkin.vis
	var analyzer:SpectralAnalyzer;
	var levels:Array<Bar>;
	var levelMax:Int = 0;

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (customSpeaker) {
            if ((daCustomSpeaker is ABotSpeaker || daCustomSpeaker is PixelABot) && gf != null) {
                animationFinished = gf.isAnimationFinished();
                transitionState();
            }
        } else {
            if (analyzer == null) return;
            levels = analyzer.getLevels(levels);
            var oldLevelMax = levelMax;
            levelMax = 0;
            for (i in 0...Std.int(Math.min(7, levels.length))) {
                var animFrame:Int = Math.round(levels[i].value * 5);
    
                #if desktop
                animFrame = Math.round(animFrame * MathTools.logToLinear(FlxG.sound.volume));
                #end
                
                animFrame = Math.floor(Math.min(5, animFrame));
                animFrame = Math.floor(Math.max(0, animFrame));
                animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!
                
                levelMax = Std.int(Math.max(levelMax, 5 - animFrame));
            }
    
            if (oldLevelMax <= levelMax && levelMax >= 4) {
                if (atlasSpeaker != null) {
                    atlasSpeaker.anim.play('boom', true);
                } else if (spriteSpeaker != null) {
                    spriteSpeaker.animation.play('boom', true);
                }
            }
        }
    }

    public function initAnalyzer() {
        @:privateAccess
        analyzer = new SpectralAnalyzer(snd._channel.__audioSource, 7, 0.1, 40);
    
		// This is from Vanilla Funkin Source

		// A-Bot tuning...
		analyzer.minDb = -65;
		analyzer.maxDb = -25;
		analyzer.maxFreq = 22000;
		// we use a very low minFreq since some songs use low low subbass like a boss
		analyzer.minFreq = 10;

		// End of base funkin code

        #if desktop
        // On desktop it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
        // So we want to manually change it!
        analyzer.fftN = 256;
        #end
    }
    #end

    // For stage stuff
    public function createPost() {
        if(gf != null && customSpeaker && (daCustomSpeaker is ABotSpeaker || daCustomSpeaker is PixelABot)) {
			gf.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
				switch(currentNeneState) {
					case STATE_PRE_RAISE:
						if (name == 'danceLeft' && frameNumber >= 14) {
							animationFinished = true;
							transitionState();
						}
					default:
						// Ignore.
				}
			}
		}
    }
    public function beatHit() {
        if (customSpeaker && (daCustomSpeaker is ABotSpeaker || daCustomSpeaker is PixelABot)) {
            switch(currentNeneState) {
                case STATE_READY:
                    if (blinkCountdown == 0) {
                        if (gf.curCharacter == 'nene') gf.playAnim('idleKnife', false);
                        blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
                    }
                    else blinkCountdown--;
                default:
                    // In other states, don't interrupt the existing animation.
            }
        }
    }
    public function songStart() {
        if (customSpeaker && (daCustomSpeaker is ABotSpeaker || daCustomSpeaker is PixelABot)) {
            gf.animation.finishCallback = onNeneAnimationFinished;
        }
    }


    // Abot Stuff
	var blinkCountdown:Int = 3;
	final VULTURE_THRESHOLD:Float = 0.5;
	final MIN_BLINK_DELAY:Int = 3;
	final MAX_BLINK_DELAY:Int = 7;
	var animationFinished:Bool = false;
	var currentNeneState:NeneState = STATE_DEFAULT;

    function onNeneAnimationFinished(name:String) {
		@:privateAccess
        if(!PlayState.instance.startedCountdown) return;
		switch(currentNeneState) {
			case STATE_RAISE, STATE_LOWER:
				if (name == 'raiseKnife' || name == 'lowerKnife') {
					animationFinished = true;
					transitionState();
				}
			default:
				// Ignore.
		}
	}

    function transitionState() {
		switch (currentNeneState) {
			case STATE_DEFAULT:
				if (PlayState.instance.health <= VULTURE_THRESHOLD) {
					currentNeneState = STATE_PRE_RAISE;
					gf.skipDance = true;
				}
			case STATE_PRE_RAISE:
				if (PlayState.instance.health > VULTURE_THRESHOLD) {
					currentNeneState = STATE_DEFAULT;
					gf.skipDance = false;
				} else if (animationFinished) {
					currentNeneState = STATE_RAISE;
					gf.playAnim('raiseKnife');
					gf.skipDance = true;
					gf.danced = true;
					animationFinished = false;
				}
			case STATE_RAISE:
				if (animationFinished) {
					currentNeneState = STATE_READY;
					animationFinished = false;
				}
			case STATE_READY:
				if (PlayState.instance.health > VULTURE_THRESHOLD) {
					currentNeneState = STATE_LOWER;
					gf.playAnim('lowerKnife');
				}
			case STATE_LOWER:
				if (animationFinished) {
					currentNeneState = STATE_DEFAULT;
					animationFinished = false;
					gf.skipDance = false;
				}
		}
    }

    public var snd(default, set):FlxSound;
	function set_snd(changed:FlxSound) {
		snd = changed;
		#if funkin.vis
		initAnalyzer();
		#end
        if (customSpeaker) {
            if (daCustomSpeaker is ABotSpeaker || daCustomSpeaker is PixelABot) {
                daCustomSpeaker.snd = changed;
                #if funkin.vis
                daCustomSpeaker.initAnalyzer();
                #end
            }
        }
		return snd;
	}
}

enum NeneState {
	STATE_DEFAULT;
	STATE_PRE_RAISE;
	STATE_RAISE;
	STATE_READY;
	STATE_LOWER;
}

typedef SpeakerSettings = {
    var beatAnim:String;
    @:optional var gfOffsets:Array<Float>;
    @:optional var library:String;
    @:optional var offsets:Array<Float>;
    @:optional var isAnimateAtlas:Bool;
}