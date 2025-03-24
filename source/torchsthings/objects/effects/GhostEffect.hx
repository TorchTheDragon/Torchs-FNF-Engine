package torchsthings.objects.effects;

import objects.Character;
import objects.Note;

class GhostEffect {
    public static var coloredGhost:Bool = true;
    public static var arrowColorGhost:Bool = true;
    public static var tweenTime:Float = 0.4;
    public static var slideDistance:Float = 90.0;

    public static function createGhost(char:Character, player:Int, note:Note) {
        var ghost:GhostChar = new GhostChar(char);
        if (player == 1) {
            PlayState.instance.addBehindBF(ghost);
        } else {
            PlayState.instance.addBehindDad(ghost);
        }

        var noteColors:Bool = (ClientPrefs.data.characterNoteColors == 'Enabled');
        var enemyNotes:Bool = (ClientPrefs.data.characterNoteColors == 'Opponent Only');

        var colors:Array<FlxColor> = [
            ((noteColors || enemyNotes && player == 0) && arrowColorGhost) ? ghost.charRef.noteColors.left[0] : PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[0][0] : ClientPrefs.data.arrowRGB[0][0], 
            ((noteColors || enemyNotes && player == 0) && arrowColorGhost) ? ghost.charRef.noteColors.down[0] : PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[1][0] : ClientPrefs.data.arrowRGB[1][0], 
            ((noteColors || enemyNotes && player == 0) && arrowColorGhost) ? ghost.charRef.noteColors.up[0] : PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[2][0] : ClientPrefs.data.arrowRGB[2][0], 
            ((noteColors || enemyNotes && player == 0) && arrowColorGhost) ? ghost.charRef.noteColors.right[0] : PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[3][0] : ClientPrefs.data.arrowRGB[3][0]];
        for (i in 0...colors.length) {
            colors[i].alphaFloat = 0.15;
        }

        var defaultColor:FlxColor = ghost.color;
        defaultColor.alphaFloat = 0.9;

        function ghostKill(t:FlxTween) {
            ghost.kill();
            ghost.destroy();
        }

        switch (note.noteData) {
            case 0:
                if (coloredGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[0]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                if (slideDistance == 0) {
                    ghost.scale.set(1.2, 1.2);
                    FlxTween.tween(ghost, {"scale.x": ghost.charRef.scale.x, "scale.y": ghost.charRef.scale.y}, tweenTime, {onComplete: ghostKill});
                } else {
                    FlxTween.tween(ghost, {x: char.x - slideDistance}, tweenTime, {onComplete: ghostKill});
                }
            case 1:
                if (coloredGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[1]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                if (slideDistance == 0) {
                    ghost.scale.set(1.2, 1.2);
                    FlxTween.tween(ghost, {"scale.x": ghost.charRef.scale.x, "scale.y": ghost.charRef.scale.y}, tweenTime, {onComplete: ghostKill});
                } else {
                    FlxTween.tween(ghost, {y: char.y + slideDistance}, tweenTime, {onComplete: ghostKill});
                }
            case 2:
                if (coloredGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[2]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                if (slideDistance == 0) {
                    ghost.scale.set(1.2, 1.2);
                    FlxTween.tween(ghost, {"scale.x": ghost.charRef.scale.x, "scale.y": ghost.charRef.scale.y}, tweenTime, {onComplete: ghostKill});
                } else {
                    FlxTween.tween(ghost, {y: char.y - slideDistance}, tweenTime, {onComplete: ghostKill});
                }
            case 3:
                if (coloredGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[3]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                if (slideDistance == 0) {
                    ghost.scale.set(1.2, 1.2);
                    FlxTween.tween(ghost, {"scale.x": ghost.charRef.scale.x, "scale.y": ghost.charRef.scale.y}, tweenTime, {onComplete: ghostKill});
                } else {
                    FlxTween.tween(ghost, {x: char.x + slideDistance}, tweenTime, {onComplete: ghostKill});
                }
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
        frameName = charRef.isAnimateAtlas ? charRef.atlas.anim.curSymbol.name : charRef.animation.curAnim.name;
        curFrame = charRef.isAnimateAtlas ? charRef.atlas.anim.curSymbol.curFrame : charRef.animation.curAnim.curFrame;
        this.shader = charRef.shader;
        this.dance();
    }

    override function update(elapsed:Float) {
        //this.offset.x = offsets[0];
        //this.offset.y = offsets[1];
        this.offset.set(offsets[0], offsets[1]);
        if (charRef.isAnimateAtlas == true && charRef.atlas.anim.curSymbol != null) {
            this.atlas.anim.play(frameName, true, false, curFrame);
        } else {
            this.animation.play(frameName, true, false, curFrame);
        }
        super.update(elapsed);
    }
}