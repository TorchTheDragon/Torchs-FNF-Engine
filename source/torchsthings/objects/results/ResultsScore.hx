package torchsthings.objects.results;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;

class ResultsScore extends FlxTypedSpriteGroup<ScoreNum> {
    public var score(default, set):Int = 0;
    public var scoreStart:Int = 0;

    function set_score(value:Float):Int {
        if (group == null || group.members == null) return Std.parseInt(Std.string(value));

        var loop:Int = group.members.length - 1;
        var number:Int = Std.parseInt(Std.string(value));
        var prevNum:ScoreNum;

        while (number > 0) {
            scoreStart += 1;
            group.members[loop].finalDigit = number % 10;
            number = Math.floor(number / 10);
            loop--;
        }

        while (loop > 0) {
            group.members[loop].digit = 10;
            loop--;
        }

        return Std.parseInt(Std.string(value));
    }

    public function new(x:Float, y:Float, digitCount:Int, score:Int = 100) {
        super(x, y);

        for (i in 0...digitCount) {
            add(new ScoreNum(x + (65 * i), y));
        }

        this.score = score;
    }

    public function animateNumbers() {
        for (i in (group.members.length - scoreStart)...group.members.length) {
            new FlxTimer().start((i - 1) / 24, _ -> {
                group.members[i].finalDelay = scoreStart - (i - 1);
                group.members[i].playAnim();
                group.members[i].shuffle();
            });
        }
    }

    public function updateScore(score:Int) {
        this.score = score;
    }
}

class ScoreNum extends FlxSprite {
    public var digit(default, set):Int = 10;
    public var finalDigit(default, set):Int = 10;
    public var glow:Bool = true;

    var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "DISABLED"];
    
    function set_finalDigit(value:Int):Int {
        animation.play('GONE', true, false, 0);

        return finalDigit = value;
    }

    function set_digit(value:Int):Int {
        if (value >= 0 && animation.curAnim != null && animation.curAnim.name != numToString[value]) {
            if (glow) { 
                animation.play(numToString[value], true, false, 0);
                glow = false;
            } else {
                animation.play(numToString[value], true, false, 4);
            }

            updateHitbox();

            switch (value) {
                default:
                    centerOffsets(false);
            }
        }

        return digit = value;
    }

    public function playAnim() {
        animation.play(numToString[digit], true, false, 0);
    }

    public var shuffleTimer:FlxTimer;
    public var finalTween:FlxTween;
    public var finalDelay:Float = 0;
    public var baseCoords:Array<Float> = [0, 0];

    function finishShuffleTween() {
        var tweenFunction = function(x) {
            var digitRounded = Math.floor(x);
            digit = digitRounded;
        };
        
        finalTween = FlxTween.num(0.0, finalDigit, 23 / 24, {
            ease: FlxEase.quadOut,
            onComplete: function (twn:FlxTween) {
                new FlxTimer().start((finalDelay) / 24, _ -> {
                    animation.play(animation.curAnim.name, true, false, 0);
                });
            }
        }, tweenFunction);
    }

    function shuffleProgress(shuffleTimer:FlxTimer) {
        var tempDigit:Int = digit;
        tempDigit += 1;
        if (tempDigit > 9) tempDigit = 0;
        if (tempDigit < 0) tempDigit = 0;
        digit = tempDigit;

        if (shuffleTimer.loops > 0 && shuffleTimer.loopsLeft == 0) {
            finishShuffleTween();
        }
    }

    public function shuffle() {
        var duration:Float = 41/24;
        var interval:Float = 1/24;
        shuffleTimer = new FlxTimer().start(interval, shuffleProgress, Std.int(duration / interval));
    }

    public function new(x:Float, y:Float) {
        super(x, y);

        baseCoords = [x, y];

        frames = Paths.getSparrowAtlas('results_screen/score-digital-numbers', 'torchs_assets');

        for (i in 0...10) {
            var stringNum:String = numToString[i];
            animation.addByPrefix(stringNum, '$stringNum DIGITAL', 24, false);
        }

        animation.addByPrefix('GONE', 'GONE', 24, false);
        animation.addByPrefix('DISABLED', 'DISABLED', 24, false);

        this.digit = 10;

        animation.play(numToString[digit], true);

        updateHitbox();
    }
}