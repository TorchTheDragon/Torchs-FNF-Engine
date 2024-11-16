package torchsthings.states;

import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import openfl.utils.Assets;
import torchsthings.objects.results.ClearPercentCounter;
import torchsthings.objects.results.ResultsScore;
import torchsthings.objects.results.TallyCounter;
import torchsthings.shaders.LeftMaskShader;

import states.FreeplayState;
import states.StoryMenuState;

using StringTools;

class ResultsScreen extends MusicBeatState {
    var background:FlxSprite;
    var backgroundFlash:FlxSprite;

    var songName:FlxBitmapText;
    var rank:Int = 0;
    var difficulty:FlxSprite;
    var diffShader:LeftMaskShader = new LeftMaskShader();
    var songNameShader:LeftMaskShader = new LeftMaskShader();
    var songDiff:String = 'unknown';
    var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);
    var clearPercentCounter:ClearPercentCounter;
    var clearPercent:Int = 0;
    var movingSongStuff:Bool = false;

    var ratingsPopin:FlxSprite;
    var scorePopin:FlxSprite;
    var resultsAnim:FlxSprite;

    var sicks:Int = 0;
    var goods:Int = 0;
    var bads:Int = 0;
    var shits:Int = 0;
    var maxCombo:Int = 0;
    var misses:Int = 0;
    var totalHit:Int = 0;

    var score:ResultsScore;
    var highscoreNew:FlxSprite;
    
    var resultSprites:Array<Dynamic> = [];
    var spritesWithDelays:Array<Dynamic> = [];
    var spriteDelays:Array<Float> = [];

    var storyMode:Bool = false;

    var mainCamera:FlxCamera;
    var scrollCamera:FlxCamera;
    var backgroundCamera:FlxCamera;

    var newHighScore:Bool = false;

    var rankTextGroup:FlxTypedGroup<FlxBackdrop>; // Just did this to make the vertical rank text appear behind the black topper

    var specificChar:String = 'bf';

    var tweenObjects:Array<Dynamic> = [];

    function rankToInt(rank:String):Int {
        var ranks:Array<String> = ['You Suck!', 'Shit', 'Bad', 'Bruh', 'Meh', 'Nice', 'Good', 'Great', 'Sick!', 'Perfect!!'];
        if (ranks.contains(rank)) return ranks.indexOf(rank);
        else return 0;
    }

    function charAnimPicker(?char:String = 'bf'):String { // Add more depending on what characters can be used for the results screen
        switch (char.toLowerCase().trim()) {
            case 'pico' | 'pico-player':
                return 'pico';
            default:
                return 'bf';
        }
    }

    public function new(song:String, rating:String, finalScore:Float, diff:String, results:Array<Int>, curHighScore:Float, ?storyMode:Bool = false, ?char:String) {
        super();

        sicks = results[0];
        goods = results[1];
        bads = results[2];
        shits = results[3];
        misses = results[4];
        maxCombo = results[5];
        totalHit = sicks + goods + bads + shits;
        clearPercent = results[6];
        if (finalScore > curHighScore) newHighScore = true;
        this.storyMode = storyMode;
        specificChar = charAnimPicker(char);

        var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890";
        rank = rankToInt(rating);

        songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image('results_screen/alphabet', 'torchs_assets'), fontLetters, FlxPoint.get(49, 62)));
        songName.text = FlxStringUtil.toTitleCase(song);
        songName.letterSpacing = -15;
        songName.angle = -4.4;

        difficulty = new FlxSprite(555);
        songDiff = diff.toLowerCase();

        clearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
        clearPercentCounter.visible = false;

        backgroundFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);

        resultsAnim = new FlxSprite(-200, -10);
        resultsAnim.frames = Paths.getSparrowAtlas('results_screen/results', 'torchs_assets');

        ratingsPopin = new FlxSprite(-135, 135);
        ratingsPopin.frames = Paths.getSparrowAtlas('results_screen/ratingsPopin', 'torchs_assets');

        scorePopin = new FlxSprite(-180, 515);
        scorePopin.frames = Paths.getSparrowAtlas('results_screen/scorePopin', 'torchs_assets');

        highscoreNew = new FlxSprite(44, 557);
        highscoreNew.frames = Paths.getSparrowAtlas('results_screen/highscoreNew', 'torchs_assets');

        score = new ResultsScore(35, 305, 10, Std.parseInt(Std.string(finalScore)));
    }

    override function create() {
        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        mainCamera = initPsychCamera();
        scrollCamera = new FlxCamera();
        backgroundCamera = new FlxCamera();
        scrollCamera.angle = -3.8;
        mainCamera.bgColor = FlxColor.TRANSPARENT;
        scrollCamera.bgColor = FlxColor.TRANSPARENT;
        backgroundCamera.bgColor = FlxColor.MAGENTA;

        FlxG.cameras.add(backgroundCamera, false);
        FlxG.cameras.add(scrollCamera, false);
        FlxG.cameras.add(mainCamera, false);
        FlxG.cameras.setDefaultDrawTarget(mainCamera, true);
        this.camera = mainCamera;
        FlxG.camera.zoom = 1.0;

        background = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90);
        background.scrollFactor.set();
        background.cameras = [backgroundCamera];
        add(background);

        backgroundFlash.scrollFactor.set();
        backgroundFlash.visible = false;
        add(backgroundFlash);

        addResultAnimation(specificChar);
        var soundSystem:FlxSprite = new FlxSprite(-15, -180);
        soundSystem.frames = Paths.getSparrowAtlas('results_screen/soundSystem', 'torchs_assets');
        soundSystem.animation.addByPrefix('idle', 'sound system', 24, false);
        soundSystem.visible = false;
        new FlxTimer().start(8 / 24, _ -> {
            soundSystem.animation.play('idle');
            soundSystem.visible = true;
        });
        add(soundSystem);

        // Only checking the folder to prevent having to hard code every difficulty image name
        var songDiffs:Array<String> = Paths.getDirectoryFiles('results_screen/diffs', 'images', 'torchs_assets');
        for (i in 0...songDiffs.length) {
            songDiffs[i] = songDiffs[i].replace('.png', '');
        }

        if (!songDiffs.contains(songDiff)) songDiff = 'unknown';
        difficulty.loadGraphic(Paths.image('results_screen/diffs/' + songDiff, 'torchs_assets'));
        add(difficulty);

        if (clearPercentCounter != null) add(clearPercentCounter);

        add(songName);

        var angleRad = songName.angle * (Math.PI / 180);
        speedOfTween.x = -1 * Math.cos(angleRad);
        speedOfTween.y = -1 * Math.sin(angleRad);

        songName.shader = songNameShader;
        difficulty.shader = diffShader;
        diffShader.swagMaskX = difficulty.x - 15;

        rankTextGroup = new FlxTypedGroup<FlxBackdrop>(); // Just did this to make the vertical rank text appear behind the black topper
        add(rankTextGroup);

        var topBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image('results_screen/topBarBlack', 'torchs_assets'));
        topBar.y = -topBar.height;
        FlxTween.tween(topBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24});
        add(topBar);

        resultsAnim.animation.addByPrefix('result', 'results instance 1', 24, false);
        resultsAnim.visible = false;
        add(resultsAnim);
        new FlxTimer().start(6 / 24, _ -> {
            resultsAnim.visible = true;
            resultsAnim.animation.play('result');
        });

        ratingsPopin.animation.addByPrefix('idle', 'Categories', 24, false);
        ratingsPopin.visible = false;
        add(ratingsPopin);
        new FlxTimer().start(21 / 24, _ -> {
            ratingsPopin.visible = true;
            ratingsPopin.animation.play('idle');
        });

        scorePopin.animation.addByPrefix("score", 'tally score', 24, false);
        scorePopin.visible = false;
        add(scorePopin);
        new FlxTimer().start(37 / 24, _ -> {
            scorePopin.visible = true;
            scorePopin.animation.play('score');
            scorePopin.animation.finishCallback = anim -> {};
        });

        new FlxTimer().start(37 / 24, _ -> {
            score.visible = true;
            score.animateNumbers();
            startRankTallyTimer();
        });

        new FlxTimer().start(getDelays('intro'), _ -> {
            playDaAnimations();
            timerThenSongName(1.0, false);
        });

        new FlxTimer().start(getDelays('flash'), _ -> {
            diplayRankText();
        });

        highscoreNew.animation.addByPrefix('new', 'highscoreAnim0', 24, false);
        highscoreNew.visible = false;
        highscoreNew.updateHitbox();
        add(highscoreNew);

        new FlxTimer().start(getDelays('highscore'), _ -> {
            if (newHighScore) {
                highscoreNew.visible = true;
                highscoreNew.animation.play('new');
                highscoreNew.animation.finishCallback = _ -> highscoreNew.animation.play('new', true, false, 16);
            } else {
                highscoreNew.visible = false;
            }
        });

        var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
        add(ratingGrp);

        var hStuf:Int = 50;

        var totalHitCounter:TallyCounter = new TallyCounter(375 - ((totalHit >= 1000) ? 50 : 0), (hStuf * 3), totalHit);
        ratingGrp.add(totalHitCounter);
        var maxComboCounter:TallyCounter = new TallyCounter(375 - ((maxCombo >= 1000) ? 50 : 0), (hStuf * 4), maxCombo);
        ratingGrp.add(maxComboCounter);

        hStuf += 4;
        var extraYOffset:Float = 7;

        var tallySick:TallyCounter = new TallyCounter(230, (hStuf * 5) + extraYOffset, sicks, 0xFF89E59E);
        ratingGrp.add(tallySick);
        var tallyGood:TallyCounter = new TallyCounter(210, (hStuf * 6) + extraYOffset, goods, 0xFF89C9E5);
        ratingGrp.add(tallyGood);
        var tallyBad:TallyCounter = new TallyCounter(190, (hStuf * 7) + extraYOffset, bads, 0xFFE6CF8A);
        ratingGrp.add(tallyBad);
        var tallyShit:TallyCounter = new TallyCounter(220, (hStuf * 8) + extraYOffset, shits, 0xFFE68A8A);
        ratingGrp.add(tallyShit);
        var tallyMissed:TallyCounter = new TallyCounter(260, (hStuf * 9) + extraYOffset, misses, 0xFFC68AE6);
        ratingGrp.add(tallyMissed);

        score.visible = false;
        add(score); 

        for (ind => rating in ratingGrp.members) {
            rating.visible = false;
            new FlxTimer().start((0.3 * ind) + 1.20, _ -> {
                rating.visible = true;
                FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
            });
        }

        new FlxTimer().start(getDelays('music'), _ -> {
            if (Assets.exists(Paths.musicAsString('results/' + specificChar + '/' + rankNumToRating(rank) + '-intro', 'torchs_assets'))) {
                FlxG.sound.play(Paths.music('results/' + specificChar + '/' + rankNumToRating(rank) + '-intro', 'torchs_assets'), 1.0, false, null, true, () -> {
                    FlxG.sound.playMusic(Paths.music('results/' + specificChar + '/' + rankNumToRating(rank), 'torchs_assets'), 1.0, true);
                });
            } else if (Assets.exists(Paths.musicAsString('results/' + specificChar + '/' + rankNumToRating(rank), 'torchs_assets'))) {
                FlxG.sound.playMusic(Paths.music('results/' + specificChar + '/' + rankNumToRating(rank), 'torchs_assets'), 1.0, true);
            } else if (Paths.music('results/$specificChar/NORMAL', 'torchs_assets') != null){
                FlxG.sound.playMusic(Paths.music('results/$specificChar/NORMAL', 'torchs_assets'), 1.0, true);
            } else FlxG.sound.playMusic(Paths.music('results/bf/NORMAL', 'torchs_assets'), 1.0, true);
        });
        super.create();
    }

    function diplayRankText() {
        backgroundFlash.visible = true;
        backgroundFlash.alpha = 1;
        FlxTween.tween(backgroundFlash, {alpha: 0}, 14 / 24);

        var rankText:String = (rankNumToRating(rank) == 'SHIT') ? 'LOSS' : rankNumToRating(rank);

        var rankTextVert:FlxBackdrop = new FlxBackdrop(Paths.image('results_screen/rankText/rankText' + rankText, 'torchs_assets'), Y, 0, 30);
        rankTextVert.x = FlxG.width - 44;
        rankTextVert.y = 100;
        //add(rankTextVert);
        rankTextGroup.add(rankTextVert); // Just did this to make the vertical rank text appear behind the black topper

        FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);

        new FlxTimer().start(30 / 24, _ -> {
            rankTextVert.velocity.y = -80;
        });

        for (i in 0...12) {
            var rankTextBack:FlxBackdrop = new FlxBackdrop(Paths.image('results_screen/rankText/rankScroll' + rankText, 'torchs_assets'), X, 10, 0);
            rankTextBack.x = FlxG.width / 2 - 320;
            rankTextBack.y = 50 + (135 * i / 2) + 10;
            rankTextBack.cameras = [scrollCamera];
            add(rankTextBack);
            rankTextBack.velocity.x = (i % 2 == 0) ? -7.0 : 7.0;
        }
    }

    var clearPercentLerp:Int = 0;

    function startRankTallyTimer() {
        backgroundFlash.visible = true;
        FlxTween.tween(backgroundFlash, {alpha: 0}, 5 / 24);
        clearPercentLerp = Std.int(Math.max(0, clearPercent - 36));

        var clearPercentCounter:ClearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 190, FlxG.height / 2 - 70, clearPercentLerp);
        FlxTween.tween(clearPercentCounter, {curNumber: clearPercent}, 58 / 24, {
            ease: FlxEase.quartOut,
            onUpdate: _ -> {
                clearPercentLerp = Math.round(clearPercentLerp);
                clearPercentCounter.curNumber = Math.round(clearPercentCounter.curNumber);

                if (clearPercentLerp != clearPercentCounter.curNumber) {
                    clearPercentLerp = clearPercentCounter.curNumber;
					FlxG.sound.play(Paths.sound('scrollMenu'));
                }
            },
            onComplete: _ -> {
				FlxG.sound.play(Paths.sound('confirmMenu'));
                clearPercentCounter.curNumber = clearPercent;
                clearPercentCounter.flash(true);
                new FlxTimer().start(0.4, _ -> {
                    clearPercentCounter.flash(false);
                });

                new FlxTimer().start(0.25, _ -> {
                    FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5, {
                        startDelay: 0.5,
                        ease: FlxEase.quartOut,
                        onComplete: _ -> {
                            remove(clearPercentCounter);
                        }
                    });
                });
            }
        });
        add(clearPercentCounter);
        if (ratingsPopin != null) {
            ratingsPopin.animation.finishCallback = anim -> {
                if (newHighScore) {
                    highscoreNew.visible = true;
                    highscoreNew.animation.play('new');
                } else {
                    highscoreNew.visible = false;
                }
            };
        }
    }

    function showClearPercent() {
        if (clearPercentCounter != null) {
            clearPercentCounter.visible = true;
            clearPercentCounter.flash(true);
            new FlxTimer().start(0.4, _ -> {
                clearPercentCounter.flash(false);
            });

            clearPercentCounter.curNumber = clearPercent;
        }

        new FlxTimer().start(2.5, _ -> {
            movingSongStuff = true;
        });
    }

    override function draw() {
        super.draw();
        songName.clipRect = FlxRect.get(Math.max(0, 540 - songName.x), 0, FlxG.width, songName.height);
        clearPercentCounter.clipRect = FlxRect.get(Math.max(0, 590 - clearPercentCounter.x) - 50, -10, FlxG.width, clearPercentCounter.height + 25);
    }

    function timerThenSongName(timerLength:Float = 3.0, autoScroll:Bool = true) {
        movingSongStuff = false;
        difficulty.x = 555;
        difficulty.y = -difficulty.height;
        FlxTween.tween(difficulty, {y: 122}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});
        
        if (clearPercentCounter != null) {
            clearPercentCounter.x = (difficulty.x + difficulty.width) + 60;
            clearPercentCounter.y = -clearPercentCounter.height;
            FlxTween.tween(clearPercentCounter, {y: 117}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.85});
        }

        songName.y = -songName.height;
        FlxTween.tween(songName, {y: 97 - (10 * (songName.text.length / 15))}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
        songName.x = clearPercentCounter.x + 94;

        showClearPercent();

        new FlxTimer().start(timerLength, _ -> {
            var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);
            speedOfTween.set(0, 0);
            FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});
            movingSongStuff = (autoScroll);
        });
    }

    function getDelays(delay_name:String):Float {
        var rating:String = rankNumToRating(rank);

        switch (delay_name.toLowerCase().trim()) {
            case 'intro':
                switch (rating) {
                    case 'PERFECT' | 'GREAT' | 'GOOD' | 'SHIT':
                        return 95 / 24;
                    case 'EXCELLENT':
                        return 97 / 24;
                    default:
                        return 3.5;
                }
            case 'music':
                switch (rating) {
                    case 'PERFECT':
                        return 95 / 24;
                    case 'EXCELLENT':
                        return 0;
                    case 'GREAT':
                        return 5 / 24;
                    case 'GOOD':
                        return 3 / 24;
                    case 'SHIT':
                        return 2 / 24;
                    default:
                        return 3.5;
                }
            case 'flash':
                switch (rating) {
                    case 'PERFECT' | 'EXCELLENT':
                        return 140 / 24;
                    case 'GREAT':
                        return 129 / 24;
                    case 'GOOD':
                        return 127 / 24;
                    case 'SHIT':
                        return 207 / 24;
                    default:
                        return 3.5;
                }
            case 'highscore':
                switch (rating) {
                    case 'PERFECT' | 'EXCELLENT':
                        return 140 / 24;
                    case 'GREAT':
                        return 129 / 24;
                    case 'GOOD':
                        return 127 / 24;
                    case 'SHIT':
                        return 207 / 24;
                    default: 
                        return 3.5;
                }
            default:
                return 3.5;
        }
    }

    function rankNumToRating(rank:Int):String {
        var num:Int = switch (rank) {
            case 9:
                4;
            case 8:
                3;
            case 7: 
                2;
            case 4 | 5 | 6:
                1;
            default:
                0;
        }
        var words:Array<String> = ['SHIT', 'GOOD', 'GREAT', 'EXCELLENT', 'PERFECT'];
        return words[num];
    }

    function resultAnimData(?char:String = 'bf', ?isOther:Bool = false, ?otherFolder:String = ''):ResultAnimData {
        var desti:String = isOther ? 'results_screen/' + char + ((otherFolder != '') ? '/${otherFolder}/' : '') + rankNumToRating(rank) : 'results_screen/' + char + '/' + rankNumToRating(rank);
        var data:ResultAnimData = haxe.Json.parse(Assets.getText(Paths.json(desti, 'torchs_assets')));
        if (data == null) {
            data = {
                rank: "GOOD",
                offsets: [662, 371],
                animation_delay: 0,
                scale: 1,
                animation_type: "spritemap",
                loop_name: "stuffs/loopage",
                intro_name: "stuffs/intro",
                char_name: "bf",
                file_name: "",
                other_folder: "gf",
                on_top: false,
                library: "torchs_assets",
                tweenIn: false,
                visibleWhileTweening: false
            }
        }
        return data;
    }

    function makeObj(obj:Dynamic, data:ResultAnimData, ?isOtherObj:Bool = false, ?animatesOnTopArray:Array<Dynamic>):Dynamic {
        if (data.char_name == null) data.char_name = 'bf';
        if (data.file_name == null) data.file_name = 'boyfriend';
        if (data.rank == null) data.rank = 'GOOD';
        if (data.library == null) data.library = 'torchs_assets';
        if (data.animation_delay < 0) data.animation_delay = 0; 
        /*
        On StAtIc PlAtFoRmS, nUlL cAn'T bE uSeD aS bAsIc TyPe BoOl...
        BRUH I WAS TRYING TO SET A DEFAULT VALUE, CHILL

        if (data.tweenIn == null) data.tweenIn = false;
        if (data.visibleWhileTweening == null) data.visibleWhileTweening = false;
        */
        var desti:String = 'results_screen/characterResults/${data.char_name}/' + ((isOtherObj && data.other_folder != '' && data.other_folder != null) ? '${data.rank}/${data.other_folder}' : data.rank);

        if (data.intro_name == null) data.intro_name = ((data.animation_type == 'spritemap') ? 'stuffs/introShit' : 'introShit');
        if (data.loop_name == null) data.loop_name = ((data.animation_type == 'spritemap') ? 'stuffs/loopage' : 'loopage');

        switch (data.animation_type) {
            case 'spritemap':
                obj = new FlxAnimate();
                obj.showPivot = false;
                Paths.loadAnimateAtlasWithLibrary(obj, desti, data.library);
                obj.anim.addBySymbol('intro', data.intro_name, 24, false);
                obj.anim.addBySymbol('idle', data.loop_name, 24, true);
                obj.anim.play('intro');
                obj.anim.onComplete = function() {obj.anim.play('idle', true);}
                obj.anim.pause();
            case 'sparrowatlas':
                obj = new FlxSprite();
                obj.frames = Paths.getSparrowAtlas(desti + '/${data.file_name}', data.library);
                obj.animation.addByPrefix('intro', data.intro_name, 24, false);
                obj.animation.addByPrefix('idle', data.loop_name, 24, true);
                obj.animation.play('intro');
                obj.animation.finishCallback = function(name:String) {obj.animation.play('idle', true);}
                obj.animation.pause();
        }
        obj.antialiasing = ClientPrefs.data.antialiasing;
        obj.x = data.offsets[0];
        obj.y = data.offsets[1];
        obj.scale.set(data.scale, data.scale);
        obj.visible = false;
        if (data.animation_delay > 0) {
            spritesWithDelays.push(obj);
            spriteDelays.push(data.animation_delay);
        } else resultSprites.push(obj);
        
        if (data.on_top) {
            resultSprites.remove(obj);
            animatesOnTopArray.push(obj);
        } else if (isOtherObj) add(obj);

        if (data.tweenIn) {
            tweenObjects.push(obj);
        }
        return obj;
    }

    function tweenObj(obj:Dynamic, data:ResultAnimData) {
        obj.x -= 1500; // Hopefully this is far enough offscreen
        if (data.visibleWhileTweening) obj.visible = true;
        FlxTween.tween(obj, {x: data.offsets[0]}, getDelays('intro'), {ease: FlxEase.expoOut, startDelay: getDelays('intro')});
        // Only plays the animation to make it not appear static while sliding
        new FlxTimer().start(getDelays('intro') / 2, _ -> {
            if (Std.isOfType(obj, FlxAnimate)) {
                obj.anim.play();
            } else if (Std.isOfType(obj, FlxSprite)) {
                obj.animation.play('intro');
            }
        });
    }

    function addResultAnimation(?char:String = 'bf') {
        var animatesOnTop:Array<Dynamic> = [];
        var mainObj:Dynamic = new FlxAnimate();
        var data:ResultAnimData = resultAnimData(char);
        mainObj = makeObj(mainObj, data);
        var otherData:ResultAnimData = null;
        
        var otherObj:Dynamic = new FlxSprite();
        if (data.other_folder != null && data.other_folder != '') {
            otherData = resultAnimData(char, true, data.other_folder);
            otherObj = makeObj(otherObj, otherData, true, animatesOnTop);
        } 

        if (tweenObjects.contains(mainObj)) {
            tweenObj(mainObj, data);
        }
        if (tweenObjects.contains(otherObj)) {
            tweenObj(otherObj, otherData);
        }

        add(mainObj);
        for (thingy in animatesOnTop) {
            add(thingy);
        }
    }

    function playDaAnimations() {
        for (sprite in resultSprites) {
            sprite.visible = true;
            if (!tweenObjects.contains(sprite)) {
                if (Std.isOfType(sprite, FlxAnimate)) {
                    sprite.anim.play();
                } else if (Std.isOfType(sprite, FlxSprite)) {
                    sprite.animation.play('intro');
                }
            }
        }
        for (i in 0...spritesWithDelays.length) {
            new FlxTimer().start(spriteDelays[i], function(tmr:FlxTimer) {
                spritesWithDelays[i].visible = true;
                if (Std.isOfType(spritesWithDelays[i], FlxAnimate)) {
                    spritesWithDelays[i].anim.play();
                } else if (Std.isOfType(spritesWithDelays[i], FlxSprite)) {
                    spritesWithDelays[i].animation.play('intro');
                }
            });
        }
    }

    override function update(elapsed:Float) {
        diffShader.swagSprX = difficulty.x;

        if (movingSongStuff) {
            songName.x += speedOfTween.x;
            difficulty.x += speedOfTween.x;
            clearPercentCounter.x += speedOfTween.x;
            songName.y += speedOfTween.y;
            difficulty.y += speedOfTween.y;
            clearPercentCounter.y += speedOfTween.y;

            if (songName.x + songName.width < 100) {
                timerThenSongName();
            }
        }

        // Debug Keys only for testing the result screen songs and animations
        if (FlxG.keys.justPressed.ONE) {
            LoadingState.loadAndSwitchState(new ResultsScreen('test', 'You Suck', 2, 'hard', [0, 0, 0, 5, 100, 5, 10], 0, specificChar));
        }
        if (FlxG.keys.justPressed.TWO) {
            LoadingState.loadAndSwitchState(new ResultsScreen('test', 'Nice', 6969, 'hard', [420, 69, 0, 34, 50, 69, 40], 0, specificChar));
        }
        if (FlxG.keys.justPressed.THREE) {
            LoadingState.loadAndSwitchState(new ResultsScreen('test', 'Great', 10000, 'hard', [325, 125, 0, 10, 7, 125, 60], 0, specificChar));
        }
        if (FlxG.keys.justPressed.FOUR) {
            LoadingState.loadAndSwitchState(new ResultsScreen('test', 'Sick!', 250000, 'hard', [500, 25, 0, 0, 2, 425, 80], 0, specificChar));
        }
        if (FlxG.keys.justPressed.FIVE) {
            LoadingState.loadAndSwitchState(new ResultsScreen('test', 'Perfect!!', 999999, 'hard', [9999, 0, 0, 0, 0, 9999, 100], 0, specificChar));
        }
        // Remove these keys on finish

        if (FlxG.keys.justPressed.ENTER) {
            if (FlxG.sound.music != null) FlxG.sound.music.stop();
            FlxG.sound.playMusic(Paths.music('freakyMenu'));

            if (storyMode) {
                LoadingState.loadAndSwitchState(new StoryMenuState());
            } else {
                LoadingState.loadAndSwitchState(new FreeplayState());
            }
        }
        super.update(elapsed);
    }
}

typedef ResultAnimData = {
    var rank:String; // The rating obtained
    var offsets:Array<Float>; // The object offsets
    var animation_delay:Float; // The delay before the animation starts
    var scale:Float; // The scale of the object
    var animation_type:String; // The type of animation
    var loop_name:String; // The name or symbol of the looping animation
    var intro_name:String; // The name or symbol of the intro animation
    var char_name:String; // Used for specific character result animations
    var file_name:String; // If it is a sparrow atlas, this is the file name
    var other_folder:String; // Only used if another animation is present as well. Ex, the Hearts or a background GF
    var on_top:Bool; // Only used for Other to appear above the main character
    var library:String; // If for some reason you choose to change the library
    var tweenIn:Bool; // Only use this for things like Pico's loss state to have the object already exist, but tween in from the left to its main point
    var visibleWhileTweening:Bool; // Sounds dumb but is here as a just in case
}