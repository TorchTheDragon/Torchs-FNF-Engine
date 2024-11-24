package torchsthings.objects.results;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;

class TallyCounter extends FlxTypedSpriteGroup<FlxSprite> {
    public var curNumber:Float = 0;
    public var neededNumber:Int = 0;
    public var flavor:FlxColor = 0xFFFFFFFF;
    public var align:FlxTextAlign = FlxTextAlign.LEFT;

    var tmr:Float = 0;

    public function new(x:Float, y:Float, neededNumber:Int = 0, ?flavor:FlxColor = 0xFFFFFFFF, align:FlxTextAlign = FlxTextAlign.LEFT) {
        super(x, y);
        this.align = align;
        this.flavor = flavor;
        this.neededNumber = neededNumber;
        if (curNumber == neededNumber) {drawNumbers();}
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if (curNumber < neededNumber) {drawNumbers();}
    }

    function drawNumbers() {
        var seperatedScore:Array<Int> = [];
        var tempCombo:Int = Math.round(curNumber);
        var fullNumberDigits:Int = Std.int(Math.max(1, Math.ceil(Math.log(neededNumber) / Math.log(10))));

        while (tempCombo != 0) {
            seperatedScore.push(tempCombo % 10);
            tempCombo = Math.floor(tempCombo / 10);
        }

        if (seperatedScore.length == 0) seperatedScore.push(0);

        seperatedScore.reverse();

        for (ind => num in seperatedScore) {
            if (ind >= members.length) {
                var xPos = ind * (43 * this.scale.x);
                if (this.align == FlxTextAlign.RIGHT) {
                    xPos -= (fullNumberDigits * (43 * this.scale.x));
                }
                var numb:TallyNumber = new TallyNumber(xPos, 0, num);
                numb.scale.set(this.scale.x, this.scale.y);
                numb.antialiasing = ClientPrefs.data.antialiasing;
                add(numb);
                numb.color = flavor;
            } else {
                members[ind].animation.play(Std.string(num));
                members[ind].color = flavor;
            }
        }
    }
}

class TallyNumber extends FlxSprite {
    public function new(x:Float, y:Float, digit:Int) {
        super(x, y);
        frames = Paths.getSparrowAtlas('results_screen/tallieNumber', 'torchs_assets');
        for (i in 0...10) {
            animation.addByPrefix(Std.string(i), i + ' small', 24, true);
        }
        animation.play(Std.string(digit));
        updateHitbox();
    }
}