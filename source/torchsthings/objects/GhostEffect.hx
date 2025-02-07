package torchsthings.objects;

import objects.Character;
import objects.Note;

class GhostEffect {
    public static var arrowColorGhost:Bool = true;
    public static var tweenTime:Float = 0.4;
    public static var slideDistance:Float = 250.0;

    public static function createGhost(char:Character, player:Int, note:Note) {
        var ghost:GhostChar = new GhostChar(char);
        if (player == 1) {
            PlayState.instance.addBehindBF(ghost);
        } else {
            PlayState.instance.addBehindDad(ghost);
        }

        var leftArrowColor:FlxColor = ghost.charRef.noteColors.left[0];
        leftArrowColor.alphaFloat = 0.15;
        var upArrowColor:FlxColor = ghost.charRef.noteColors.up[0];
        upArrowColor.alphaFloat = 0.15;
        var downArrowColor:FlxColor = ghost.charRef.noteColors.down[0];
        downArrowColor.alphaFloat = 0.15;
        var rightArrowColor:FlxColor = ghost.charRef.noteColors.right[0];
        rightArrowColor.alphaFloat = 0.15;

        var defaultColor:FlxColor = ghost.color;
        defaultColor.alphaFloat = 0.9;

        switch (note.noteData) {
            case 0:
                if (arrowColorGhost) FlxTween.color(ghost, tweenTime, defaultColor, leftArrowColor);
                else FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                FlxTween.tween(ghost, {x: char.x - slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
            case 1:
                if (arrowColorGhost) FlxTween.color(ghost, tweenTime, defaultColor, downArrowColor);
                else FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                FlxTween.tween(ghost, {y: char.y + slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
            case 2:
                if (arrowColorGhost) FlxTween.color(ghost, tweenTime, defaultColor, upArrowColor); 
                else FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                FlxTween.tween(ghost, {y: char.y - slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
            case 3:
                if (arrowColorGhost) FlxTween.color(ghost, tweenTime, defaultColor, rightArrowColor); 
                else FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                FlxTween.tween(ghost, {x: char.x + slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
        }
    }
}

class GhostChar extends Character {
    public var charRef:Character = null;
    var frameName:String = '';
    var curFrame:Int = 0;
    var offsets:Array<Float> = [0.0, 0.0];

    public function new (char:Character) {
        super(char.x, char.y, char.curCharacter, char.isPlayer);
        charRef = char;
        this.scale.set(charRef.scale.x, charRef.scale.y);
        this.alpha = charRef.alpha; 
        offsets = [charRef.offset.x, charRef.offset.y];
        if (charRef.isAnimateAtlas) {
            frameName = charRef.atlas.anim.curSymbol.name;
            curFrame = charRef.atlas.anim.curSymbol.curFrame;
        } else {
            frameName = charRef.animation.curAnim.name;
            curFrame = charRef.animation.curAnim.curFrame;
        }
        this.dance();
    }

    override function update(elapsed:Float) {
        this.offset.x = offsets[0];
        this.offset.y = offsets[1];
        if (charRef.isAnimateAtlas == true && charRef.atlas.anim.curSymbol != null) {
            this.atlas.anim.play(frameName, true, false, curFrame);
        } else {
            this.animation.play(frameName, true, false, curFrame);
        }
        super.update(elapsed);
    }
}