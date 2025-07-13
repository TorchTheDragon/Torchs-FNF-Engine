package states.stages.cutscenes;

import states.stages.MallErect;
import states.stages.objects.MallCrowdErect;
import cutscenes.CutsceneHandler;
import objects.Character;
import flixel.util.FlxSignal;
import flash.display.BlendMode;
import flixel.FlxObject;
import backend.BaseStage;
import torchsthings.shaders.AdjustColorShader;
class CutsceneMallErect {
    //PreloadCutscene

    var stage:MallErect;
    public var dadmom:FlxAnimate;
    var santa:FlxAnimate;
    var audio:FlxSound;
    var blackScreen:FlxSprite;
    var camFollow:FlxObject;

    public function new (stage:MallErect)
    {
        this.stage = stage;
        this.camFollow = stage.camFollow;
    }

    var cutsceneHandler:CutsceneHandler;

    function prepareEggnogCutscene() {
        var game = PlayState.instance;
		cutsceneHandler = new CutsceneHandler(false);
		stage.santa.visible = false;
		stage.dad.visible = true;
        cutsceneHandler.useCurLevel = true;
        dadmom = new FlxAnimate(100, 100);
        Paths.loadAnimateAtlasFromLibrary(dadmom, 'christmas/erect/cutscene/parents_shoot_assets', "week5");
        dadmom.antialiasing = ClientPrefs.data.antialiasing;
        dadmom.anim.addBySymbol("olaa","parents whole scene", 24, false);
        santa = new FlxAnimate(100, 100);
        Paths.loadAnimateAtlasFromLibrary(santa, 'christmas/erect/cutscene/santa_speaks_assets', "week5");
        santa.antialiasing = ClientPrefs.data.antialiasing;
        santa.anim.addBySymbol("olaa2","santa whole scene", 24, false);
        santa.setPosition(stage.santa.x + 360, stage.santa.y + 350);
        dadmom.setPosition(stage.dadGroup.x -620, stage.dadGroup.y + 400);
		santa.shader = stage.makecolorShader(-20,-15,0,-10);
		dadmom.shader = stage.makecolorShader(-20,-15,0,-10);
	
		game.inCutscene = true;
		game.isCameraOnForcedPos = true;

		Paths.sound('santa_emotion', 'week5');

		FlxTween.tween(stage.camHUD, {alpha: 0}, 1,  {ease: FlxEase.sineInOut});

		blackScreen = new FlxSprite(-600,-570).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
		blackScreen.alpha = 0;
		blackScreen.scrollFactor.set();
		blackScreen.cameras = [stage.camOther];
		game.add(blackScreen);

		cutsceneHandler.finishCallback = function() {
			game.inCutscene = false;
			stage.seenCutscene = true;
			stage.camHUD.fade(0xFF000000, 0.5, true, null, true);
			new FlxTimer().start(0.5, function(tmr) {
				game.endSong();
			});
		}
	}

    public function eggnogErectCutscene() {
		var game = PlayState.instance;
		prepareEggnogCutscene();
		cutsceneHandler.endTime = 16;

        stage.addBehindBF(dadmom);
        stage.addBehindBF(santa);

        dadmom.anim.play("olaa", true);
        santa.anim.play("olaa2", true);

		game.tweenCameraToPosition(santa.x + 300, santa.y, 2.8, FlxEase.expoOut);
		game.tweenCameraZoom(0.73, 2, true, FlxEase.quadInOut);
		game.gf.animation.finishCallback = function(name:String) {
			switch(name) {
				case 'danceLeft', 'danceRight':
					game.gf.dance();
			}
		};
		game.gf.dance();

		cutsceneHandler.timer(0.3, function () {
			FlxG.sound.play(Paths.sound('santa_emotion', 'week5'));
		});

		cutsceneHandler.timer(2.8, function() {
			game.tweenCameraToPosition(santa.x + 150, santa.y, 9, FlxEase.quartInOut);
			game.tweenCameraZoom(0.79, 9, true, FlxEase.quadInOut);
		});

		cutsceneHandler.timer(11.375, function() {
			FlxG.sound.play(Paths.sound('santa_shot_n_falls', 'week5'));
			game.gf.playAnim("sad", true);
			game.gf.specialAnim = true;
			game.gf.animation.finishCallback = function(name:String) {
				if (name == "sad") {
					game.gf.playAnim("sad", true);
				}
			};
		});
		
		cutsceneHandler.timer(12.83, function() {
			stage.camGame.shake(0.005, 0.2);
			game.tweenCameraToPosition(santa.x + 160, santa.y + 80, 5, FlxEase.expoOut);
		});

		cutsceneHandler.timer(15, function() {
			FlxTween.tween(blackScreen, {alpha: 1}, 1, {startDelay: 0.3});
		});
	}

}