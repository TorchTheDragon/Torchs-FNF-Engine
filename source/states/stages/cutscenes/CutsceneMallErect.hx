package states.stages.cutscenes;

import torchsthings.shaders.AdjustColorShader;
import states.stages.MallErect;
import states.stages.objects.MallCrowdErect;
import cutscenes.CutsceneHandler;
import objects.Character;
import flixel.util.FlxSignal;
import flash.display.BlendMode;
import flixel.FlxObject;
import backend.BaseStage;
class CutsceneMallErect {
    //PreloadCutscene
    var cutsceneHandler:CutsceneHandler;
    var stage:MallErect;
    var dadmom:FlxAnimate;
    var santa:FlxAnimate;
    var audio:FlxSound;
    var colorShader:AdjustColorShader;
    var blackScreen:FlxSprite;
    var camFollow:FlxObject;

    public function new (stage:MallErect)
    {
        this.stage = stage;
        this.camFollow = stage.camFollow;
    }

    public function preloadCutscene()
    {
        cutsceneHandler = new CutsceneHandler();
        dadmom = new FlxAnimate(100, 100);
        Paths.loadAnimateAtlasFromLibrary(dadmom, 'christmas/erect/cutscene/parents_shoot_assets', "week5");
        dadmom.antialiasing = ClientPrefs.data.antialiasing;
        santa = new FlxAnimate(100, 100);
        Paths.loadAnimateAtlasFromLibrary(santa, 'christmas/erect/cutscene/santa_speaks_assets', "week5");
        santa.antialiasing = ClientPrefs.data.antialiasing;
       
    }
    public function playCutscene():Void
    {
       cutsceneHandler.endTime = 16;
       audio = new FlxSound().loadEmbedded(Paths.sound('christmas/erect/endCutscene', "week5"), false, true);
       FlxG.sound.list.add(audio);
       
       dadmom.anim.addBySymbol("olaa","parents whole scene", 24, false);
       dadmom.anim.play("olaa", true);
       santa.anim.addBySymbol("olaa2","santa whole scene", 24, false);
       santa.anim.play("olaa2", true);

       	FlxTween.tween(FlxG.camera, {zoom: 0.73}, 2, {ease: FlxEase.quadInOut});
        if (camFollow != null) {
            FlxTween.tween(camFollow, {x: 300, y: 0}, 2.8, {ease: FlxEase.expoOut});
        }

		cutsceneHandler.timer(2.8, function() {
            FlxTween.tween(FlxG.camera, {zoom: 0.79}, 9, {ease: FlxEase.quadInOut});
        if (camFollow != null) {
            FlxTween.tween(camFollow, {x: 150, y: 0}, 9, {ease: FlxEase.quartInOut});
		  }
        });

		cutsceneHandler.timer(11.375, function() {
            if (camFollow != null) {
			FlxG.sound.play(Paths.sound('santa_shot_n_falls', "week5"));
		  }
        });
		
		cutsceneHandler.timer(12.83, function() {
            if (camFollow != null) {
            FlxTween.tween(camFollow, {x: 160, y: 80}, 5, {ease: FlxEase.quartInOut});
            }
            FlxG.camera.shake(0.005, 0.2);
		});

		cutsceneHandler.timer(15, function() {
			FlxTween.tween(blackScreen, {alpha: 1}, 1, {startDelay: 0.3});
        });
	
    }
}