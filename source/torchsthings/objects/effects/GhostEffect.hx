package torchsthings.objects.effects;

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

        var colors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];
        colors = getColors(player, ghost);
        for (i in 0...colors.length) {
            colors[i].alphaFloat = 0.15;
        }

        /*
        var leftArrowColor:FlxColor = ghost.charRef.noteColors.left[0];
        leftArrowColor.alphaFloat = 0.15;
        var upArrowColor:FlxColor = ghost.charRef.noteColors.up[0];
        upArrowColor.alphaFloat = 0.15;
        var downArrowColor:FlxColor = ghost.charRef.noteColors.down[0];
        downArrowColor.alphaFloat = 0.15;
        var rightArrowColor:FlxColor = ghost.charRef.noteColors.right[0];
        rightArrowColor.alphaFloat = 0.15;
        */

        var defaultColor:FlxColor = ghost.color;
        defaultColor.alphaFloat = 0.9;

        switch (note.noteData) {
            case 0:
                if (arrowColorGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[0]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                FlxTween.tween(ghost, {x: char.x - slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
            case 1:
                if (arrowColorGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[1]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                FlxTween.tween(ghost, {y: char.y + slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
            case 2:
                if (arrowColorGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[2]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                FlxTween.tween(ghost, {y: char.y - slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
            case 3:
                if (arrowColorGhost) {
                    FlxTween.color(ghost, tweenTime, defaultColor, colors[3]);
                } else {
                    FlxTween.tween(ghost, {alpha: 0}, tweenTime);
                }
                FlxTween.tween(ghost, {x: char.x + slideDistance}, tweenTime, {
                    onComplete: function(t:FlxTween) {
                        ghost.kill();
                        ghost.destroy();
                    }
                });
        }
    }

    static function getColors(player:Int, ghost:GhostChar):Array<FlxColor> {
        var daColors:Array<FlxColor> = [];
        if (ClientPrefs.data.characterNoteColors == 'Enabled') {
            daColors = [ghost.charRef.noteColors.left[0], ghost.charRef.noteColors.down[0], ghost.charRef.noteColors.up[0], ghost.charRef.noteColors.right[0]];
        } else if (ClientPrefs.data.characterNoteColors == 'Opponent Only') {
            if (player == 1) {
                daColors = [PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[0][0] : ClientPrefs.data.arrowRGB[0][0], PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[1][0] : ClientPrefs.data.arrowRGB[1][0], PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[2][0] : ClientPrefs.data.arrowRGB[2][0], PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[3][0] : ClientPrefs.data.arrowRGB[3][0]];
            } else {
                daColors = [ghost.charRef.noteColors.left[0], ghost.charRef.noteColors.down[0], ghost.charRef.noteColors.up[0], ghost.charRef.noteColors.right[0]];
            }
        } else {
            daColors = [PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[0][0] : ClientPrefs.data.arrowRGB[0][0], PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[1][0] : ClientPrefs.data.arrowRGB[1][0], PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[2][0] : ClientPrefs.data.arrowRGB[2][0], PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[3][0] : ClientPrefs.data.arrowRGB[3][0]];
        }
        return daColors;
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