package torchsthings.objects.effects;

import objects.Character;
import torchsthings.shaders.BlurAndFade;

class ShadowEffect {
    public static function createShadows(char:Character, ?color:FlxColor = 0xFF009CB1, ?maxYAbove:Float = 20.0, ?tag:String = '', ?shadowQuantity:Int = 3, ?speed:Float = 2.0, ?forcedDistanceChange:Float = 0) {
        var shadows:Array<Shadow> = [];
        for (i in 0...shadowQuantity) {
            var shadow:Shadow = new Shadow(char, maxYAbove, tag, speed, color, forcedDistanceChange);
            shadow.y -= (maxYAbove / shadowQuantity * i);
            shadows.push(shadow); 
        }
        return shadows;
    }
}

class Shadow extends Character {
    var charRef:Character = null;
    var maxHeight:Float = 20.0;
    public var shadowID:String = ''; // This is used for the hard coding to stop a specific shadow set. Best if named after the character
    var blurFade:BlurAndFade;
    var movementAmount:Float = 2.0;
    var forcedDistance:Float = 0.0;

    public function new(char:Character, maxHeight:Float, tag:String, speed:Float, ?color:FlxColor = 0xFF009CB1, ?forcedDistanceChange:Float = 0.0) {
        super(char.x, char.y, char.curCharacter, char.isPlayer);
        charRef = char;
        this.maxHeight = maxHeight;
        shadowID = tag;
        movementAmount = speed;
        this.color = color;
        this.alpha = 0.35;
        this.shader = blurFade = new BlurAndFade(this, 2.5, 0.5, 'shadow');
        forcedDistance = forcedDistanceChange;
        this.dance();
    }

    override function update(elapsed:Float) {
        this.offset.x = charRef.offset.x;
        this.offset.y = charRef.offset.y;
        this.y -= movementAmount;
        if (this.y <= (charRef.y - forcedDistance) - (maxHeight + forcedDistance)) {
            if (PlayState.instance.shadowEffects != null) {
                for (effect in PlayState.instance.shadowEffects) {
                    var i = effect.indexOf(this);
                    if (i >= 0 && i < effect.length - 1) {
                        effect.remove(this);
                        effect.push(this);
                        PlayState.instance.remove(this, true);
                        if (effect.length > 1) {
                            var indexBelow = PlayState.instance.members.indexOf(effect[effect.length - 2]);
                            if (indexBelow >= 0) {
                                PlayState.instance.insert(indexBelow, this);
                            } else {
                                PlayState.instance.add(this);
                            }
                        } else {
                            PlayState.instance.add(this);
                        }
                    }
                }
            } 
            this.y = charRef.y - forcedDistance;
        }
        if (charRef.isAnimateAtlas == true && charRef.atlas.anim.curSymbol != null) {
            this.atlas.anim.play(charRef.atlas.anim.curSymbol.name, true, false, charRef.atlas.anim.curSymbol.curFrame);
        } else if (charRef.animation.curAnim != null) {
            this.animation.play(charRef.animation.curAnim.name, true, false, charRef.animation.curAnim.curFrame);
        }
        blurFade.syncFrameUVs();
        super.update(elapsed);
    }
}