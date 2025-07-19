package states.stages.cutscenes;

import states.stages.TankErect;
import cutscenes.CutsceneHandler;
import objects.Character;
import flixel.util.FlxSignal;
import flash.display.BlendMode;
import flixel.FlxObject;
import backend.BaseStage;
//import torchsthings.shaders.DropShadowShader;

class CutsceneTankErect {

    //PreloadCutscene
    var stage:TankErect;
    var blackScreen:FlxSprite;
    var audio:FlxSound;
    var camFollow:FlxObject;

    public function new(stage:TankErect) {
        this.stage = stage;
        this.camFollow = stage.camFollow;
    }

    var cutsceneHandler:CutsceneHandler;

    function prepareCutscenePico() {
        var game = PlayState.instance;
        cutsceneHandler = new CutsceneHandler(false);
        cutsceneHandler.useCurLevel = true;
        game.isCameraOnForcedPos = true;
        game.inCutscene = true;

        Paths.sound('endCutscene', 'week7');

        FlxTween.tween(stage.camHUD, {alpha: 0}, 1, {ease: FlxEase.sineInOut});

            blackScreen = new FlxSprite(-600,-570).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
            blackScreen.alpha = 0;
		    blackScreen.scrollFactor.set();
            blackScreen.cameras = [game.camOther];
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
     // ola amor uwu
        public function stressPicoCutscene() {

            var game = PlayState.instance;
            prepareCutscenePico();
            cutsceneHandler.endTime = 12;
    
            game.dad.playAnim("Cutscene", true);   
    
            game.tweenCameraToPosition(game.dad.x + 800, game.dad.y + 200);
            game.tweenCameraZoom(0.65, 0.8, true, FlxEase.smoothStepOut);
            FlxG.sound.play(Paths.sound('endCutscene', "week7"));
            
            cutsceneHandler.timer(0.1, function()
                {
                    game.gf.animation.finishCallback = function(name:String) {
                        if (name == "idle") {
                            game.gf.playAnim("idle");
                        }
                    };
                    game.gf.playAnim("idle");
                        game.boyfriend.animation.finishCallback = function(name:String)
                        {
                            switch(name)
                                {
                                    case 'idle':
                                        game.boyfriend.dance();
                                }
                            }
                            game.boyfriend.dance();
                });

            cutsceneHandler.timer(7, function()
            {
                game.boyfriend.playAnim("laugh", true);
                game.boyfriend.specialAnim = true;
            });
            cutsceneHandler.timer(10.9, function()
            {
                FlxTween.tween(blackScreen, { alpha: 1}, 1, {startDelay: 0.3});
            });
            cutsceneHandler.timer (11.1, function () 
            {
                    game.tweenCameraToPosition(game.dad.x + 800, game.dad.y + 0, 4.3, FlxEase.smoothStepOut);
            });
        }

    }