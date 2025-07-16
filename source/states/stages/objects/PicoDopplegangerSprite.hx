package states.stages.objects;

import objects.FlxAtlasSprite;
import cutscenes.CutsceneHandler;

class PicoDopplegangerSprite extends FlxAtlasSprite
{

  public var isPlayer:Bool = false;
  public var cutsceneSounds:FlxSound = null; 
  var suffix:String = '';

  public function new(x:Float, y:Float)
  {
    super(x, y, 'assets/week3/images/philly/erect/cutscenes/pico_doppleganger', {
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: new FlxPoint(1, 1),
    });
  }

  public function cancelSounds(){
    if(cutsceneSounds != null) {
      cutsceneSounds.destroy();
      cutsceneSounds = null;
    }
  }

  public function doAnim(_suffix:String, shoot:Bool = false, explode:Bool = false, cutsceneHandler:CutsceneHandler){
    suffix = _suffix;

    trace('Doppelganger: doAnim(' + suffix + ', ' + shoot + ', ' + explode + ')');

    cutsceneHandler.timer(0.3, () -> {
      //if (cutsceneSounds != null) cutsceneSounds.destroy();
      cutsceneSounds = FlxG.sound.load(Paths.sound('cutscene/picoGasp', 'week3'), 1.0, false, true, true);
      cutsceneSounds.play();
    });

    if(shoot == true){
      playAnimation("shoot" + suffix, true, false, false);

      cutsceneHandler.timer(6.29, () -> {
        //if (cutsceneSounds != null) cutsceneSounds.destroy();
        cutsceneSounds = FlxG.sound.load(Paths.sound('cutscene/picoShoot', 'week3'), 1.0, false, true, true);
        cutsceneSounds.play();
      });
      cutsceneHandler.timer(10.33, () -> {
        if (cutsceneSounds != null) cutsceneSounds.destroy();
        cutsceneSounds = FlxG.sound.load(Paths.sound('cutscene/picoSpin', 'week3'), 1.0, false, true, true);
        cutsceneSounds.play();
      });
    }else{
      if(explode == true){
        playAnimation("explode" + suffix, true, false, false);

        onAnimationComplete.add(startLoop);

        cutsceneHandler.timer(3.7, () -> {
          if (cutsceneSounds != null) cutsceneSounds.destroy();
          cutsceneSounds = FlxG.sound.load(Paths.sound('cutscene/picoCigarette2', 'week3'), 1.0, false, true, true);
          cutsceneSounds.play();
        });
        cutsceneHandler.timer(8.75, () -> {
          if (cutsceneSounds != null) cutsceneSounds.destroy();
          cutsceneSounds = FlxG.sound.load(Paths.sound('cutscene/picoExplode', 'week3'), 1.0, false, true, true);
          cutsceneSounds.play();
        });
        cutsceneHandler.objects.remove(this);
      }else{
        playAnimation("cigarette" + suffix, true, false, false);

        cutsceneHandler.timer(3.7, () -> {
          if (cutsceneSounds != null) cutsceneSounds.destroy();
          cutsceneSounds = FlxG.sound.load(Paths.sound('cutscene/picoCigarette', 'week3'), 1.0, false, true, true);
          cutsceneSounds.play();
        });
      }
    }
  }

  function startLoop(x:String){
    playAnimation("loop" + suffix, true, false, true);
  }
}