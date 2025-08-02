package states.stages.cutscenes;

import objects.Character;
import cutscenes.CutsceneHandler;
import states.stages.objects.PicoDopplegangerSprite;
import states.stages.PhillyErect;
import torchsthings.shaders.*;
import torchsthings.shaders.AdjustColorShader;

class TwoPicos {
    // Cutscenes
    var cutsceneHandler:CutsceneHandler;
    var imposterPico:PicoDopplegangerSprite;
    var pico:PicoDopplegangerSprite;
    var bloodPool:FlxAnimate;
    var cigarette:FlxSprite;
    var audioPlaying:FlxSound;

    var playerShoots:Bool;
    var explode:Bool;
    var seenOutcome:Bool;
    var host:BaseStage;
    var shader:AdjustColorShader;

    public function new(host:BaseStage) {
        this.host = host;
    }

    function prepareCutscene()
    {
        shader = new AdjustColorShader();
        shader.hue = -26;
        shader.saturation = -16;
        shader.contrast = 0;
        shader.brightness = -5;

        cutsceneHandler = new CutsceneHandler(false);
        cutsceneHandler.useCurLevel = true;
        var game = PlayState.instance;

        game.isCameraOnForcedPos = true;

        host.boyfriend.visible = host.dad.visible = false;
        host.camHUD.visible = false;
        // inCutscene = true; //this would stop the camera movement, oops

        imposterPico = new PicoDopplegangerSprite(host.dad.x + 82, host.dad.y + 400);
        imposterPico.showPivot = false;
        imposterPico.antialiasing = ClientPrefs.data.antialiasing;
        cutsceneHandler.push(imposterPico);

        pico = new PicoDopplegangerSprite(host.boyfriend.x + 48.5, host.boyfriend.y + 400);
        pico.showPivot = false;
        pico.antialiasing = ClientPrefs.data.antialiasing;
        cutsceneHandler.push(pico);

        bloodPool = new FlxAnimate(0, 0);
        bloodPool.visible = false;
        Paths.loadAnimateAtlasFromLibrary(bloodPool, "philly/erect/cutscenes/bloodPool", "week3");

        cigarette = new FlxSprite();
        cigarette.frames = Paths.getSparrowAtlas('philly/erect/cutscenes/cigarette');
        cigarette.animation.addByPrefix('cigarette spit', 'cigarette spit', 24, false);
        cigarette.visible = false;

        cutsceneHandler.finishCallback = function()
        {
            host.seenCutscene = true;
            //Restore camera
            var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
            FlxG.sound.music.fadeOut(timeForStuff);
            FlxTween.tween(FlxG.camera, {zoom: host.defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});

            //Show still alive chars
            if (explode)
                {
                    if (playerShoots) host.boyfriend.visible = true;
                    else host.dad.visible = true;
                }
            else host.boyfriend.visible = host.dad.visible = true;
            
            host.camHUD.visible = true;
            game.isCameraOnForcedPos = false;

            //Crear callbacks
            host.boyfriend.animation.finishCallback = null;
            host.gf.animation.finishCallback = null;
    
            if (audioPlaying != null) audioPlaying.stop();
            //Estos dos eran los desgraciados que provoccaban el crash quizás lo resuelvo más luego :p pero por ahora se queda así 
            /*pico.cancelSounds();
            imposterPico.cancelSounds();*/			
			
            if (explode)
            {
                if(playerShoots){
                    if (seenOutcome)
                        imposterPico.playAnimation("loopOpponent", true, true, true);
                    else
                    {
                        imposterPico.kill();
                        game.remove(imposterPico);
                        imposterPico.destroy();
                        host.dad.visible = true;
                    }
                }
                else{

                    if(seenOutcome){
                        pico.playAnimation("loopPlayer", true, true, true);
                        game.endSong();
                    }
                    else{
                        pico.kill();
                        game.remove(pico);
                        pico.destroy();
                        host.boyfriend.visible = true;
                    }
                }
            }
            //Dance!
            host.dad.dance();
            host.boyfriend.dance();
            host.gf.dance();

            FlxTween.cancelTweensOf(FlxG.camera);
            FlxTween.cancelTweensOf(host.camFollow);
            @:privateAccess
            game.moveCameraSection();
            FlxG.camera.scroll.set(host.camFollow.x - FlxG.width / 2, host.camFollow.y - FlxG.height / 2);
            FlxG.camera.zoom = host.defaultCamZoom;
            if(!explode || playerShoots) game.startCountdown();
        };
        cutsceneHandler.skipCallback = function()
        {
            cutsceneHandler.finishCallback();
        };
        host.camFollow_set(host.dad.x + 280, host.dad.y + 170);
    }

    public function startCutscene()
    {
        prepareCutscene();
        var game = PlayState.instance;

        seenOutcome = false;
        //Testing variables
        // explode = true;
        // playerShoots = true;
        //50/50 chance for who shoots
        if (FlxG.random.bool(50))
        {
            playerShoots = true;
        }
        else
        {
            playerShoots = false;
        }
        if (FlxG.random.bool(8))
        {
            explode = true;
        }
        else
        {
            explode = false;
        }
        cutsceneHandler.endTime = 13;
        cutsceneHandler.music = playerShoots ? 'cutscene2' : 'cutscene';
        Paths.sound('cutscene/picoCigarette', 'week3');
        Paths.sound('cutscene/picoExplode', 'week3');
        Paths.sound('cutscene/picoShoot', 'week3');
        Paths.sound('cutscene/picoSpin', 'week3');
        Paths.sound('cutscene/picoCigarette2', 'week3');
        Paths.sound('cutscene/picoGasp', 'week3');

        var cigarettePos:Array<Float> = [];
        var shooterPos:Array<Float> = [];
        if (playerShoots == true)
        {
            cigarette.flipX = true;

            host.addBehindBF(cigarette);
            host.addBehindBF(bloodPool);
            host.addBehindBF(imposterPico);
            host.addBehindBF(pico);

            cigarette.setPosition(host.boyfriend.x - 143.5, host.boyfriend.y + 210);
            bloodPool.setPosition(host.dad.x - 1487, host.dad.y - 173);

            shooterPos = cameraPos(host.boyfriend, game.boyfriendCameraOffset);
            cigarettePos = cameraPos(host.dad, [250, 0]);
        }
        else
        {
            host.addBehindDad(cigarette);
            host.addBehindDad(bloodPool);
            host.addBehindDad(pico);
            host.addBehindDad(imposterPico);
            bloodPool.setPosition(host.boyfriend.x - 788.5, host.boyfriend.y - 173);
            cigarette.setPosition(host.boyfriend.x - 478.5, host.boyfriend.y + 205);

            cigarettePos = cameraPos(host.boyfriend, game.boyfriendCameraOffset);
            shooterPos = cameraPos(host.dad, [250, 0]);
        }
        var midPoint:Array<Float> = [(shooterPos[0] + cigarettePos[0]) / 2, (shooterPos[1] + cigarettePos[1]) / 2];

        // Allw picos to set their cutscene timers
        imposterPico.doAnim("Opponent", !playerShoots, explode, cutsceneHandler);
        pico.doAnim("Player", playerShoots, explode, cutsceneHandler);

        host.camFollow_set(midPoint[0], midPoint[1]);

        if (ClientPrefs.data.shaders)
        {
            cutsceneHandler.timer(0.01, () ->
            {
                host.gf.animation.finishCallback = function(name:String)
		        {
			        switch(name)
			        {
				    case 'danceLeft', 'danceRight':
					    host.gf.dance();
			        }
		        }
		        host.gf.dance();
                pico.shader = shader;
                imposterPico.shader = shader;
                bloodPool.shader = shader;
            });
        }

        cutsceneHandler.timer(4, () ->
        {
            host.camFollow_set(cigarettePos[0], cigarettePos[1]);
        });

        cutsceneHandler.timer(6.3, () ->
        {
            host.camFollow_set(shooterPos[0], shooterPos[1]);
        });

        cutsceneHandler.timer(8.75, () ->
        {
            seenOutcome = true;
            // cutting off skipping here. really dont think its needed after this point and it saves problems from happening
            host.camFollow_set(cigarettePos[0], cigarettePos[1]);
        });

        cutsceneHandler.timer(11.2, () ->
        {
            if (explode == true)
            {
                bloodPool.visible = true;
                bloodPool.anim.play("bloodPool", true);
            }
        });

        cutsceneHandler.timer(11.5, () ->
        {
            if (explode == false)
            {
                cigarette.visible = true;
                cigarette.animation.play('cigarette spit');
            }
        });
    }

    function cameraPos(char:Character, camOffset:Array<Float>)
    {
        var point = new FlxPoint(char.getMidpoint().x - 100, char.getMidpoint().y - 100);
        point.x -= char.cameraPosition[0] - camOffset[0];
        point.y += char.cameraPosition[1] + camOffset[1];
        return [point.x, point.y];
    }

    public function glowEvent(end:Bool)
    {
        if(explode && playerShoots)
        {
            cigarette.color = imposterPico.color = bloodPool.color = host.boyfriend.color;
            if (!end) return;
            cigarette.color = imposterPico.color = bloodPool.color = 0xFFFFFFFF;
        }
        if (cigarette != null) 
        {
            cigarette.color = host.boyfriend.color;
            if (!end) return;
            cigarette.color = 0xFFFFFFFF;
        }
    }
}