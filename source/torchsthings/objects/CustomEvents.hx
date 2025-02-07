package torchsthings.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import objects.Character;

class CustomEvents {
    static var cinematicUpperY:Float = -350.0;
    static var cinematicLowerY:Float = 720.0;

    public static function onEvent(eventName:String, value1:String, value2:String) {
        switch (eventName) {
            case 'Cinematic Bars':
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
        }
    }
}