package torchsthings.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import objects.Character;
import torchsthings.objects.effects.*;

class CustomEvents {
    static var cinematicUpperY:Float = -350.0;
    static var cinematicLowerY:Float = 720.0;
    public static var stageEvents:Array<String> = [];

    public static function onEvent(eventName:String, value1:String, value2:String) {
        switch (eventName) {
            case 'Cinematic Bars' | 'Cinematics':
                var upperBar:FlxSprite = new FlxSprite(-110, cinematicUpperY).makeGraphic(1500, 350, 0xFF000000);
                var lowerBar:FlxSprite = new FlxSprite(-110, cinematicLowerY).makeGraphic(1500, 350, 0xFF000000);
                upperBar.cameras = [PlayState.instance.camHUD];
                lowerBar.cameras = [PlayState.instance.camHUD];
                PlayState.instance.add(upperBar);
                PlayState.instance.add(lowerBar);

                var vals1:Array<String> = value1.split(",");
                var speed:Float = 0.0;
                var wait:Float = 0.0;
                if (vals1 != null) {
                    if (vals1[0] != null || vals1[0] != '') speed = Std.parseFloat(vals1[0].trim());
                    if (vals1[1] != null || vals1[1] != '') wait = Std.parseFloat(vals1[1].trim());
                }

                //var speed:Float = Std.parseFloat(value1);
                var distance:Float = Std.parseFloat(value2);
                if (distance > 200.0) distance = 200.0; else if (distance < 0.0) distance = 0.0;

                if (speed > 0 && distance > 0) {
                    FlxTween.tween(upperBar, {y: cinematicUpperY + distance}, speed, {ease: FlxEase.quadOut});
                    FlxTween.tween(lowerBar, {y: cinematicLowerY - distance}, speed, {
                        ease: FlxEase.quadOut, 
                        onComplete: function(twn:FlxTween) {
                            new FlxTimer().start(wait, function(tmr:FlxTimer) {
                                FlxTween.tween(upperBar, {y: cinematicUpperY}, speed, {ease: FlxEase.quadIn});
                                FlxTween.tween(lowerBar, {y: cinematicLowerY}, speed, {
                                    ease: FlxEase.quadIn,
                                    onComplete: function (other:FlxTween) {
                                        upperBar.kill();
                                        upperBar.destroy();
                                        lowerBar.kill();
                                        lowerBar.destroy();
                                    }
                                });
                                FlxTween.tween(PlayState.instance.healthBar, {alpha: 1}, speed/2);
                                FlxTween.tween(PlayState.instance.iconP1, {alpha: 1}, speed/2);
                                FlxTween.tween(PlayState.instance.iconP2, {alpha: 1}, speed/2);
                            });
                        }
                    });
                    FlxTween.tween(PlayState.instance.healthBar, {alpha: 0}, speed/2);
                    FlxTween.tween(PlayState.instance.iconP1, {alpha: 0}, speed/2);
                    FlxTween.tween(PlayState.instance.iconP2, {alpha: 0}, speed/2);
                }
            case "Edit Ghost Notes":
                // If the ghost is colored, if so, does it use per character colors or no?
                var vals1:Array<String>;
                if (value1 != null && value1 != '') {
                    vals1 = value1.split(',');
                    GhostEffect.coloredGhost = (vals1[0].trim().toLowerCase() == 'true');
                    if (vals1.length >= 2) {
                        GhostEffect.arrowColorGhost = (vals1[1].trim().toLowerCase() == 'true');
                    }
                }

                // TweenTime, SlideDistance
                // If slide distance is 0 then it uses scaling instead
                var vals2:Array<String>;
                if (value2 != null && value2 != '') {
                    vals2 = value2.split(',');
                    GhostEffect.tweenTime = Std.parseFloat(vals2[0].trim());
                    if (vals2.length >= 2) {
                        GhostEffect.slideDistance = Std.parseFloat(vals2[1].trim());
                    }
                }

            default: 
                if (!stageEvents.contains (eventName)) trace('Event $eventName doesn\'t exist.');
        }
    }
}