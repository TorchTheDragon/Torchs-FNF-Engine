package objectsplus;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxG;
import objects.HealthIcon;
import states.PlayState;

class IconsAnimator {

    public var iconP1:HealthIcon;
    public var iconP2:HealthIcon;
    var iconY:Float;
    
    var pBouncing:Bool = false;
    var oBouncing:Bool = false;
    var initialX1:Float;
    var initialX2:Float;

    var stretchTweenP1:FlxTween;
    var stretchTweenP2:FlxTween;

    public static var canResetProperties:Bool = true;
    
    var bounceHeight:Float = 15;
    var bounceDuration:Float = 0.5;
    var spinSpeed:Float = 0.4;

    var isAnimatingPosition:Bool = false;

    public function new(icon1:HealthIcon, icon2:HealthIcon, iconY:Float) {
        iconP1 = icon1;
        iconP2 = icon2;
        this.iconY = iconY;
        initialX1 = icon1.x;
        initialX2 = icon2.x;
    }

    public function updateIcons(curBeat:Int, iconAnims:Array<String>, bfAnim:String, dadAnim:String) {
        resetIconProperties();
        
        isAnimatingPosition = false;

        for (anim in iconAnims) {
            if(anim == 'Disabled') continue;
            
            switch(anim) {
                case "Default":
                    setIconsScale(1.2);

                case "Arrow Funk":
                    if (curBeat % 1 == 0) toggleScales(0.8, 1.2);
                    if (curBeat % 2 == 0) toggleScales(1.2, 0.8);

                case "GF Dance":
                    setIconsScale(1.2);
                    animateAngles(curBeat);

                case "Zoom In And Out":
                    setIconsScale((curBeat % 2 == 0) ? 0.8 : 1.2);

                case "Heartbeat":
                    var scale = (curBeat % 2 == 0) ? 1.3 : 1.1;
                    setIconsScale(scale);

                case "Bounce":
                    handleBounce(bfAnim, dadAnim);

                case "Spin":
                    FlxTween.angle(iconP1, iconP1.angle, iconP1.angle + 360, spinSpeed, {ease: FlxEase.quadOut});
                    FlxTween.angle(iconP2, iconP2.angle, iconP2.angle - 360, spinSpeed, {ease: FlxEase.quadOut});

                case "Color Flash":
                    var targetColor = (curBeat % 2 == 0) ? FlxColor.RED : FlxColor.CYAN;
                    FlxTween.color(iconP1, 0.2, iconP1.color, targetColor);
                    FlxTween.color(iconP2, 0.2, iconP2.color, targetColor);

                case "Stretch":
                    if (bfAnim.startsWith("sing")) {
                        if (stretchTweenP1 != null) stretchTweenP1.cancel();
                
                        stretchTweenP1 = FlxTween.tween(iconP1.scale, {x: 1.1, y: 0.8}, 0.25, {
                            ease: FlxEase.quadOut,
                            onComplete: function(tween:FlxTween) {
                                if (iconP1 != null) iconP1.scale.set(1, 1);
                                stretchTweenP1 = null;
                            }
                        });
                    }
                    if (dadAnim.startsWith("sing")) {
                        if (stretchTweenP2 != null) stretchTweenP2.cancel();
                
                        stretchTweenP2 = FlxTween.tween(iconP2.scale, {x: 1.1, y: 0.8}, 0.25, {
                            ease: FlxEase.quadOut,
                            onComplete: function(tween:FlxTween) {
                                if (iconP2 != null) iconP2.scale.set(1, 1);
                                stretchTweenP2 = null;
                            }
                        });
                    }
                
                case "Mirror Flip":
                    if (curBeat % 2 == 0) {
                        iconP1.flipX = !iconP1.flipX;
                        iconP2.flipX = !iconP2.flipX;
                    }

                case "Beat Drop":
                    if (curBeat % 4 == 0) {
                        FlxTween.tween(iconP1, {y: iconY - 50}, 0.3, {ease: FlxEase.quadOut})
                            .then(FlxTween.tween(iconP1, {y: iconY}, 0.5, {ease: FlxEase.bounceOut}));
                        
                        FlxTween.tween(iconP2, {y: iconY - 50}, 0.3, {ease: FlxEase.quadOut})
                            .then(FlxTween.tween(iconP2, {y: iconY}, 0.5, {ease: FlxEase.bounceOut}));
                    }

                case "Color Cycle":
                    var hue = (curBeat * 30) % 360;
                    iconP1.color = FlxColor.fromHSB(hue, 0.9, 1);
                    iconP2.color = FlxColor.fromHSB(hue + 180, 0.9, 1);

                case "Fade In and Out":
                    var targetAlpha = (curBeat % 2 == 0) ? 0.5 : 1;
                    FlxTween.tween(iconP1, {alpha: targetAlpha}, 0.5, {ease: FlxEase.quadOut});
                    FlxTween.tween(iconP2, {alpha: targetAlpha}, 0.5, {ease: FlxEase.quadOut});

                case "Vertical Shake":
                    var shakeDuration:Float = 0.3;
                    var shakeMagnitude:Float = 20;
                    var offset:Float = FlxG.random.float(-shakeMagnitude, shakeMagnitude);
                    
                    iconP1.y = iconY + offset;
                    iconP2.y = iconY + offset;
                    
                    FlxTween.tween(iconP1, {y: iconY}, shakeDuration, {ease: FlxEase.sineOut});
                    FlxTween.tween(iconP2, {y: iconY}, shakeDuration, {ease: FlxEase.sineOut});

                case "Pulse":
                    var pulseScale = (curBeat % 2 == 0) ? 1.1 : 0.9;
                    FlxTween.tween(iconP1.scale, {x: pulseScale, y: pulseScale}, 0.25, {ease: FlxEase.quadOut});
                    FlxTween.tween(iconP2.scale, {x: pulseScale, y: pulseScale}, 0.25, {ease: FlxEase.quadOut});

                case "Wobble":
                    var wobbleAngle = (curBeat % 2 == 0) ? 15 : -15;
                    FlxTween.tween(iconP1, {angle: wobbleAngle}, 0.25, {ease: FlxEase.quadOut});
                    FlxTween.tween(iconP2, {angle: wobbleAngle}, 0.25, {ease: FlxEase.quadOut});

                case "Pop":
                    var popScale = (curBeat % 2 == 0) ? 1.3 : 1.0;
                    FlxTween.tween(iconP1.scale, {x: popScale, y: popScale}, 0.1, {ease: FlxEase.quadOut});
                    FlxTween.tween(iconP2.scale, {x: popScale, y: popScale}, 0.1, {ease: FlxEase.quadOut});

                case "Tilt":
                    var tiltAngle = (curBeat % 2 == 0) ? 10 : -10;
                    FlxTween.tween(iconP1, {angle: tiltAngle}, 0.25, {ease: FlxEase.quadOut});
                    FlxTween.tween(iconP2, {angle: tiltAngle}, 0.25, {ease: FlxEase.quadOut});

                case "Glow":
                    var glowAlpha = (curBeat % 2 == 0) ? 0.5 : 1;
                    FlxTween.tween(iconP1, {alpha: glowAlpha}, 0.5, {ease: FlxEase.quadOut});
                    FlxTween.tween(iconP2, {alpha: glowAlpha}, 0.5, {ease: FlxEase.quadOut});
            }
        }

        iconP1.updateHitbox();
        iconP2.updateHitbox();
    }

    function resetPosition(tween:FlxTween) {
        isAnimatingPosition = false;
    }

    function resetIconProperties() {
        if (!canResetProperties) return;
        iconP1.setPosition(initialX1, iconY);
        iconP2.setPosition(initialX2, iconY);
        iconP1.flipX = iconP2.flipX = false;
        iconP1.alpha = iconP2.alpha = 1;
        iconP1.scale.set(1, 1);
        iconP2.scale.set(1, 1);
        iconP1.color = iconP2.color = FlxColor.WHITE;
        iconP1.angle = iconP2.angle = 0;
    }

    function setIconsScale(scale:Float) {
        iconP1.scale.set(scale, scale);
        iconP2.scale.set(scale, scale);
    }

    function toggleScales(scale1:Float, scale2:Float) {
        iconP1.scale.set(scale1, scale1);
        iconP2.scale.set(scale2, scale2);
    }

    function animateAngles(curBeat:Int) {
        iconP1.angle = (curBeat % 2 == 0) ? 10 : -10;
        iconP2.angle = (curBeat % 2 == 0) ? 10 : -10;
    }

    function handleBounce(bfAnim:String, dadAnim:String) {
        if (!pBouncing && bfAnim.startsWith("sing")) {
            pBouncing = true;
            bounceIcon(true);
        }
        if (!oBouncing && dadAnim.startsWith("sing")) {
            oBouncing = true;
            bounceIcon(false);
        }
    }

    function bounceIcon(isPlayer:Bool) {
        final icon = isPlayer ? iconP1 : iconP2;
        FlxTween.tween(icon, {y: iconY - bounceHeight}, bounceDuration / 2, {
            ease: FlxEase.quintOut,
            onComplete: _ -> bounceDown(icon, isPlayer)
        });
    }

    function bounceDown(icon:FlxSprite, isPlayer:Bool) {
        FlxTween.tween(icon, {y: iconY}, bounceDuration / 2, {
            ease: FlxEase.sineIn,
            onComplete: _ -> {
                if (isPlayer) pBouncing = false;
                else oBouncing = false;
            }
        });
    }

    public dynamic function updateIconsPosition() {
        var iconOffset:Int = 26;
        if (!isAnimatingPosition && PlayState.instance != null && PlayState.instance.healthBar != null) {
            iconP1.x = PlayState.instance.healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
            iconP2.x = PlayState.instance.healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
        }
    }

    public function destroy() {
        if (stretchTweenP1 != null) stretchTweenP1.cancel();
        if (stretchTweenP2 != null) stretchTweenP2.cancel();
        FlxTween.cancelTweensOf(iconP1.scale);
        FlxTween.cancelTweensOf(iconP2.scale);
    
        iconP1 = null;
        iconP2 = null;
    }
}