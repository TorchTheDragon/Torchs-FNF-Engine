package options;

import options.OptionsState;
import states.TitleState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import objects.Alphabet;
import objects.HealthIcon;
import lawsthings.objects.IconsAnimator;
import torchsthings.utils.WindowUtils;

class IconDanceSubMenu extends MusicBeatSubstate
{
    public var availableAnims:Array<String>;
    public var primaryIndex:Int;
    public var secondaryIndex:Int;
    public var onConfirm:Void->Void;

    private var modalBg:FlxSprite;
    private var primaryText:Alphabet;
    private var secondaryText:Alphabet;
    private var instructions:FlxText;

    var iconP1:HealthIcon;
    var iconP2:HealthIcon;
    var iconsAnimator:IconsAnimator;
    var animacionFalsa:String = "singUP";
    var animacionFalsa2:String = "singDOWN";

    var curAnimations:Array<String>;
    var lastBeatHit:Int = -1;

    public function new(availableAnims:Array<String>, currentPrimary:Int, currentSecondary:Int, onConfirm:Void->Void)
    {
		WindowUtils.changeTitle(WindowUtils.baseTitle + " - Icon Dance Menu");
        super();
        this.availableAnims = availableAnims;
        primaryIndex = currentPrimary;
        secondaryIndex = currentSecondary;
        this.onConfirm = onConfirm;
    }

    override public function create():Void
    {
        super.create();

        modalBg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
        modalBg.screenCenter();
        modalBg.alpha = 0;
        add(modalBg);

        primaryText = new Alphabet(0, 0, "Primary: " + availableAnims[primaryIndex], true);
        primaryText.screenCenter();
        primaryText.x -= 130;
        primaryText.y = modalBg.y + 60;
        primaryText.alpha = 0;
        primaryText.bold = true;
        add(primaryText);

        secondaryText = new Alphabet(0, 0, "Secondary: " + availableAnims[secondaryIndex], true);
        secondaryText.screenCenter();
        secondaryText.x -= 100;
        secondaryText.y = modalBg.y + 130;
        secondaryText.alpha = 0;
        secondaryText.bold = true;
        add(secondaryText);

        iconP1 = new HealthIcon('bf', true);
        iconP1.screenCenter();
        iconP1.x += 100;
        iconP1.y = modalBg.y + 250;
        iconP1.alpha = 0;
        add(iconP1);

        iconP2 = new HealthIcon('dad', false);
        iconP2.screenCenter();
        iconP2.x -= 100; 
        iconP2.y = modalBg.y + 250;
        iconP2.alpha = 0;
        add(iconP2);

        iconsAnimator = new IconsAnimator(iconP1, iconP2, iconP1.y);

        instructions = new FlxText(0, 0, FlxG.width, "Left/Right: Change primary Anim | Up/Down: Change secondary Anim | ENTER: Confirm | ESC: Cancel");
        instructions.setFormat("vcr.ttf", 24, 0xAAAAAA, "center");
        instructions.screenCenter();
        instructions.y = FlxG.height - 60;
        instructions.alpha = 0;
        add(instructions);

        FlxTween.tween(modalBg, {alpha: 0.9}, 0.5, {ease: FlxEase.quadOut});
        FlxTween.tween(primaryText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0});
        FlxTween.tween(secondaryText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.1});
        FlxTween.tween(iconP1, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.2});
        FlxTween.tween(iconP2, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.2});
        FlxTween.tween(instructions, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.3});

        Conductor.bpm = 128.0;
        FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);
    }

    override public function update(elapsed:Float):Void
    {
        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;
        super.update(elapsed);

        if (FlxG.keys.justPressed.LEFT)
        {
            primaryIndex = (primaryIndex - 1 + availableAnims.length) % availableAnims.length;
            primaryText.text = "Primary: " + availableAnims[primaryIndex];
            checkConflictingAnimations();
        }
        else if (FlxG.keys.justPressed.RIGHT)
        {
            primaryIndex = (primaryIndex + 1) % availableAnims.length;
            primaryText.text = "Primary: " + availableAnims[primaryIndex];
            checkConflictingAnimations();
        }

        if (FlxG.keys.justPressed.UP)
        {
            secondaryIndex = (secondaryIndex - 1 + availableAnims.length) % availableAnims.length;
            secondaryText.text = "Secondary: " + availableAnims[secondaryIndex];
            checkConflictingAnimations();
        }
        else if (FlxG.keys.justPressed.DOWN)
        {
            secondaryIndex = (secondaryIndex + 1) % availableAnims.length;
            secondaryText.text = "Secondary: " + availableAnims[secondaryIndex];
            checkConflictingAnimations();
        }

        if (FlxG.keys.justPressed.ENTER)
        {
            if(OptionsState.onPlayState)
            {
                if(ClientPrefs.data.pauseMusic != 'None')
                    FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
                else
                    FlxG.sound.music.volume = 0;
            }
            else FlxG.sound.playMusic(Paths.music('freakyMenu'));
            ClientPrefs.data.iconAnims = [ availableAnims[primaryIndex], availableAnims[secondaryIndex] ];
            if (onConfirm != null)
                onConfirm();
            closeMenu();
        }

        if (FlxG.keys.justPressed.ESCAPE)
        {
            if(OptionsState.onPlayState)
            {
                if(ClientPrefs.data.pauseMusic != 'None')
                    FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
                else
                    FlxG.sound.music.volume = 0;
            }
            else FlxG.sound.playMusic(Paths.music('freakyMenu'));
            closeMenu();
        }

        curAnimations = [availableAnims[primaryIndex], availableAnims[secondaryIndex]];
        Conductor.songPosition = FlxG.sound.music.time;
    }

    override function beatHit()
    {
        super.beatHit();

        if(lastBeatHit == curBeat)
        {
            return;
        }
        lastBeatHit = curBeat;

        if (animacionFalsa == "")
        {
            animacionFalsa = "singUP";
            animacionFalsa2 = "";
        }
        else
        {
            animacionFalsa = "";
            animacionFalsa2 = "singDOWN";
        }

        iconsAnimator.updateIcons(curBeat, curAnimations, animacionFalsa, animacionFalsa2);
        
        iconP1.updateHitbox();
        iconP2.updateHitbox();
    }

	function hasConflict(anim1:String, anim2:String, conflicts:Map<String, Array<String>>):Bool
    {
        return conflicts.exists(anim1) && conflicts[anim1].indexOf(anim2) != -1;
    }

    function checkConflictingAnimations():Void
	{
		var primaryAnim = availableAnims[primaryIndex];
		var secondaryAnim = availableAnims[secondaryIndex];
		//trace('Verificando: $primaryAnim vs $secondaryAnim');
        trace('Animations: [$primaryAnim & $secondaryAnim]');
	
		var conflictingAnimations:Map<String, Array<String>> = [
			"Spin" => ["Tilt", "GF Dance", "Wobble"], // Nombres exactos
			"Tilt" => ["Spin", "GF Dance", "Wobble"],
			"Bounce" => ["Vertical Shake", "Beat Drop"],
			"Vertical Shake" => ["Bounce", "Beat Drop"],
			"Color Flash" => ["Color Cycle", "Glow"],
			"Color Cycle" => ["Color Flash", "Glow"],
			"Fade In and Out" => ["Glow", "Color Flash"],
			"Glow" => ["Fade In and Out", "Color Flash", "Color Cycle"],
			"GF Dance" => ["Spin", "Tilt", "Wobble"],
			"Wobble" => ["Spin", "Tilt", "GF Dance"],
			"Beat Drop" => ["Bounce", "Vertical Shake"]
		];
	
		var maxAttempts = availableAnims.length;
		var attempts = 0;
	
		while (hasConflict(primaryAnim, secondaryAnim, conflictingAnimations) && attempts < maxAttempts)
		{
			secondaryIndex = (secondaryIndex + 1) % availableAnims.length;
			secondaryAnim = availableAnims[secondaryIndex];
			attempts++;
			//trace('Ajustando secundaria a: $secondaryAnim');
            trace('Adjusting secondary animation to: $secondaryAnim');
		}
	
		if (attempts >= maxAttempts)
		{
			//FlxG.log.warn("No se encontró animación secundaria compatible.");
            FlxG.log.warn("No compatible secondary animation found.");
		}
	
		secondaryText.text = "Secondary: " + secondaryAnim;
	
		if (hasConflict(secondaryAnim, primaryAnim, conflictingAnimations))
		{
			//showConflictMessage("Conflicto detectado. Ajustando animación primaria.");
            showConflictMessage('Animation conflict detected. Adjusting primary animation.');
			primaryIndex = (primaryIndex + 1) % availableAnims.length;
			primaryText.text = "Primary: " + availableAnims[primaryIndex];
		}
	}
	
	function showConflictMessage(message:String):Void
	{
		var conflictMessage = new FlxText(0, 0, FlxG.width, message);
		conflictMessage.setFormat("vcr.ttf", 16, 0xFF0000, "center");
		conflictMessage.screenCenter();
		conflictMessage.y = FlxG.height * 0.5; // Posición central
		conflictMessage.alpha = 0;
		add(conflictMessage);
	
		FlxTween.tween(conflictMessage, {alpha: 1}, 0.25, {
			ease: FlxEase.quadOut,
			onComplete: function(tween:FlxTween) {
				FlxTween.tween(conflictMessage, {alpha: 0}, 0.5, {
					ease: FlxEase.quadIn,
					startDelay: 1.0,
					onComplete: function(tween:FlxTween) {
						remove(conflictMessage);
					}
				});
			}
		});
	}

    override function destroy() {
        // Cancelar y liberar tweens del IconsAnimator
        if (iconsAnimator != null) {
            iconsAnimator.destroy();
            iconsAnimator = null;
        }
    
        // Destruir íconos
        if (iconP1 != null) {
            remove(iconP1);
            iconP1.kill();
            iconP1.destroy();
            //iconP1 = null;
        }
        if (iconP2 != null) {
            remove(iconP2);
            iconP2.kill();
            iconP2.destroy();
            //iconP2 = null;
        }
    
        super.destroy();
    }
    
    function closeMenu():Void {
        FlxTween.tween(modalBg, {alpha: 0}, 0.7, {ease: FlxEase.quadIn});
        FlxTween.tween(primaryText, {alpha: 0}, 0.7, {ease: FlxEase.quadIn});
        FlxTween.tween(secondaryText, {alpha: 0}, 0.7, {ease: FlxEase.quadIn, startDelay: 0.1});
        FlxTween.tween(iconP1, {alpha: 0}, 0.6, {ease: FlxEase.quadIn, startDelay: 0.2});
        FlxTween.tween(iconP2, {alpha: 0}, 0.6, {ease: FlxEase.quadIn, startDelay: 0.2});
        FlxTween.tween(instructions, {alpha: 0}, 0.5, {ease: FlxEase.quadIn, startDelay: 0.3, onComplete: function(t:FlxTween) {
            close();
        }});
    
        /*
        var timer = new FlxTimer();
        timer.start(1, function(timer:FlxTimer) {
            close();
        });
        */
    }
}