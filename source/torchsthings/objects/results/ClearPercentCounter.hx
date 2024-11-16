package torchsthings.objects.results;

import torchsthings.shaders.PureColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class ClearPercentCounter extends FlxTypedSpriteGroup<FlxSprite> {
    public var curNumber(default, set):Int = 0;
    var numberChanged:Bool = false;

    function set_curNumber(num:Int):Int {
        numberChanged = true;
        return curNumber = num;
    }

    var small:Bool = false;
    var flashShader:PureColor;

    public function new(x:Float, y:Float, startingNumber:Int = 0, small:Bool = false) {
        super(x, y);

        flashShader = new PureColor(FlxColor.WHITE);
        flashShader.colorSet = false;
        curNumber = startingNumber;
        this.small = small;

        var clearPercentText:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('results_screen/clearPercent/clearPercentText${small ? 'Small' : ''}', 'torchs_assets'));
        clearPercentText.x = small ? 40 : 0;
        add(clearPercentText);

        drawNumbers();
    }

    public function flash(enabled:Bool) {
        flashShader.colorSet = enabled;
    }

    var tmr:Float = 0;

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (numberChanged) drawNumbers();
    }

    function drawNumbers() {
        var seperatedScore:Array<Int> = [];
        var tempCombo:Int = Math.round(curNumber);

        while (tempCombo != 0) {
            seperatedScore.push(tempCombo % 10);
            tempCombo = Math.floor(tempCombo / 10);
        }

        if (seperatedScore.length == 0) seperatedScore.push(0);

        seperatedScore.reverse();

        for (ind => num in seperatedScore) {
            var digitIndex:Int = ind + 1;
            var digitOffset = (seperatedScore.length == 1) ? 1 : (seperatedScore.length == 3) ? -1 : 0;
            var digitSize = small ? 32 : 72;
            var digitHeightOffset = small ? -4 : 0;

            var xPos = (digitIndex - 1 + digitOffset) * (digitSize * this.scale.x);
            xPos += small ? -24 : 0;
            var yPos = (digitIndex - 1 + digitOffset) * (digitHeightOffset * this.scale.y);
            yPos += small ? 0 : 72;

            if (digitIndex >= members.length) {
                var variant:Bool = (seperatedScore.length == 3) ? (digitIndex >= 2) : (digitIndex >= 1);
                var numb:ClearPercentNumber = new ClearPercentNumber(xPos, yPos, num, variant, this.small);
                numb.scale.set(this.scale.x, this.scale.y);
                numb.shader = flashShader;
                numb.visible = true;
                add(numb);
            } else {
                members[digitIndex].animation.play(Std.string(num));
                members[digitIndex].x = xPos + this.x;
                members[digitIndex].y = yPos + this.y;
                members[digitIndex].visible = true;
            }
        }

        for (ind in (seperatedScore.length + 1)...(members.length)) {
            members[ind].visible = false;
        }
    }
}

class ClearPercentNumber extends FlxSprite {
    public function new(x:Float, y:Float, digit:Int, variant:Bool, small:Bool = false) {
        super(x, y);
        //trace('results_screen/clearPercent/clearPercentNumber${small ? 'Small' : variant ? 'Right' : 'Left'}');
        frames = Paths.getSparrowAtlas('results_screen/clearPercent/clearPercentNumber${small ? 'Small' : variant ? 'Right' : 'Left'}', 'torchs_assets');
        for (i in 0...10) {
            animation.addByPrefix('$i', 'number $i 0', 24, false);
        }

        animation.play('$digit');
        updateHitbox();
    }
}