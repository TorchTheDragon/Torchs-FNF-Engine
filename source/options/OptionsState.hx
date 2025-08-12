package options;

import states.MainMenuState;
import backend.StageData;
import torchsthings.utils.WindowUtils;

class OptionsState extends MusicBeatState
{
    public static var menuBG:FlxSprite;
    public static var onPlayState:Bool = false;
    public static var curSelected:Int = 0;

    var menuItems:FlxTypedGroup<FlxSprite>;

    var optionShit:Array<String> = [
        'psych',
        'torch'
    ];

    function openSelectedSubstate(label:String) {
        switch(label)
        {
            case 'psych':
                MusicBeatState.switchState(new options.PsychEngineSettingsState());
            case 'torch':
                openSubState(new options.TorchsEngineSettingsState());
        }
    }

    function createMenuItem(name:String, x:Float, y:Float):FlxSprite
    {
        var menuItem:FlxSprite = new FlxSprite(x, y);
        menuItem.frames = Paths.getSparrowAtlas('options/menu_$name');
        menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
        menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
        menuItem.animation.play('idle');
        menuItem.updateHitbox();
        menuItem.antialiasing = ClientPrefs.data.antialiasing;
        menuItem.scrollFactor.set();
        menuItems.add(menuItem);
        return menuItem;
    }

    override function create()
    {
        #if DISCORD_ALLOWED
        DiscordClient.changePresence("Options Menu", null);
        #end

        WindowUtils.changeTitle(WindowUtils.baseTitle + " - Options");

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.color = 0xFFea71fd;
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);

	var spacing:Float = 180;
	for (num => option in optionShit)
	{
		var item:FlxSprite = createMenuItem(option, 0, (num * spacing) + 150);
		item.y += (2 - optionShit.length) * 90;
		item.screenCenter(X);
	}

        changeItem();
        ClientPrefs.saveSettings();

        super.create();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.UI_UP_P)
            changeItem(-1);
        if (controls.UI_DOWN_P)
            changeItem(1);

        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if(onPlayState)
            {
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
                FlxG.sound.music.volume = 0;
            }
            else MusicBeatState.switchState(new MainMenuState());
        }
        else if (controls.ACCEPT)
        {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            openSelectedSubstate(optionShit[curSelected]);
        }
    }

    function changeItem(change:Int = 0)
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
        FlxG.sound.play(Paths.sound('scrollMenu'));

        for (item in menuItems)
        {
            item.animation.play('idle');
            item.centerOffsets();
        }

        var selectedItem = menuItems.members[curSelected];
        selectedItem.animation.play('selected');
        selectedItem.centerOffsets();
    }

    override function destroy()
    {
        ClientPrefs.loadPrefs();
        super.destroy();
    }
}
