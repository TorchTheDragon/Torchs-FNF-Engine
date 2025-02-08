package torchsthings.objects.effects;

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

    function checkCharacter(name:String):Float { // Will eventually try to make this into the character file
        switch (name) {
            case 'pico-player' | 'pico' | 'pico-playable' | 'pico-blazin':
                return -65;
            case 'gf':
                return -10;
            case 'bf-pixel-opponent':
                return -325;
            case 'torch' | 'torch-dead':
                return -75;
            default: // 'bf' is used at the default here.
                return -55;
        }
    }

    override function update(elapsed:Float) {
        this.offset.x = charRef.offset.x;
        this.offset.y = (charRef.frameHeight*charRef.scale.y) - charRef.offset.y;
        if (charRef.isAnimateAtlas == true && charRef.atlas.anim.curSymbol != null) {
            this.atlas.anim.play(charRef.atlas.anim.curSymbol.name, true, false, charRef.atlas.anim.curSymbol.curFrame);
        } else if (charRef.animation.curAnim != null) {
            this.animation.play(charRef.animation.curAnim.name, true, false, charRef.animation.curAnim.curFrame);
        }
        // YAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAYAY

        super.update(elapsed);
    }
}
