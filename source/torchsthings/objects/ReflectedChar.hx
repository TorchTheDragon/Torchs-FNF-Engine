package torchsthings.objects;

import objects.Character;
import flixel.system.FlxAssets.FlxShader;

class ReflectedChar extends Character {
    var charRef:Character = null;

    public function new(char:Character, ?alpha:Float = 0.35, ?daShader:FlxShader) {
        super(char.x, char.y + (char.frameHeight*char.scale.y*2) - char.offset.y + checkCharacter(char.curCharacter), char.curCharacter, char.isPlayer);
        charRef = char;
        this.alpha = alpha;
        this.flipY = true;
        if (daShader != null) {
            this.shader = daShader;
        }
        this.dance();
    }

    // only here if it didn't work initially
    public function setCharRef(char:Character) {
        charRef = char;
        this.x = charRef.x;
        this.y = charRef.y + (charRef.frameHeight*charRef.scale.y*2) - charRef.offset.y + checkCharacter(charRef.curCharacter);
    }

    function checkCharacter(name:String):Float {
        switch (name) {
            case 'jeys-bf':
                return -115;
            case 'pico-player' | 'pico' | 'pico-verbal':
                return -65;
            case 'pico-intro' | 'pico-intro2':
                return -70;
            case 'pico-dead':
                return -50;
            case 'gf':
                return -10;
            case 'bf-pixel-opponent':
                return -325;
            case 'bf-dead':
                return -100;
            default: // 'bf' is used at the default here.
                return -55;
        }
    }

    override function update(elapsed:Float) {
        if (charRef.animation.curAnim != null) {
            this.animation.play(charRef.animation.curAnim.name, true, false, charRef.animation.curAnim.curFrame);
        }
        this.offset.x = charRef.offset.x;
        this.offset.y = (charRef.frameHeight*charRef.scale.y) - charRef.offset.y;
        // YAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAY

        super.update(elapsed);
    }
}
