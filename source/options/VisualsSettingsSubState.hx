package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.Alphabet;
import torchsthings.objects.StrumCover;
import torchsthings.utils.WindowUtils;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var strums:FlxTypedGroup<StrumCover>;
	var noteY:Float = 90;
	public function new()
	{
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu'; //for Discord Rich Presence

		WindowUtils.changeTitle(WindowUtils.baseTitle + " - Visual Settings");

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		strums = new FlxTypedGroup<StrumCover>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			changeNoteSkin(note);
			notes.add(note);
			
			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix());
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.kill();
			splashes.add(splash);

			var strum:StrumCover = new StrumCover(note);
			strum.enemySplash = true;
			strum.showSplash = true;
			//strum.start();
			strums.add(strum);
			
			Note.initializeGlobalRGBShader(i % Note.colArray.length);
			splash.rgbShader.copyValues(Note.globalRgbShaders[i % Note.colArray.length]);
		}

		// options
		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if(noteSkins.length > 0)
		{
			if(!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); //Default skin always comes first
			var option:Option = new Option('Note Skins:',
				"Select your prefered Note skin.",
				'noteSkin',
				STRING,
				noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if(noteSplashes.length > 0)
		{
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			var option:Option = new Option('Note Splashes:',
				"Select your prefered Note Splash variation.",
				'splashSkin',
				STRING,
				noteSplashes);
			addOption(option);
			option.onChange = onChangeSplashSkin;
		}

		var option:Option = new Option('Note Splash Opacity',
			'How much transparent should the Note Splashes be.\nThis also affects Strum Covers.',
			'splashAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		option.onChange = playNoteSplashes;

		// var strumSkins:Array<String> = Mods.mergeAllTextsNamed('images/strumCovers/list.txt');
		// if (strumSkins.length > 0) {
		// 	if (!strumSkins.contains(ClientPrefs.data.strumSkin))
		// 		ClientPrefs.data.strumSkin = ClientPrefs.defaultData.strumSkin;

		// 	strumSkins.insert(0, ClientPrefs.defaultData.strumSkin);
		// 	var option:Option = new Option('Strum Covers:',
		// 		"Select your prefered Strum Cover variation.",
		// 		'strumSkin',
		// 		STRING,
		// 		strumSkins);
		// 	addOption(option);
		// 	option.onChange = playStrumCovers;
		// }

		// var option:Option = new Option('Character Based Notes:',
		// 	"Should characters override the default Note Skin and Colors?\nIf the character contains a noteskin or note colors\nthis will override them if enabled.",
		// 	'characterNoteColors',
		// 	STRING,
		// 	['Enabled', 'Opponent\nOnly', 'Disabled']);
		// addOption(option);

		// var healthSkins:Array<String> = Mods.mergeAllTextsNamed('images/healthbars/list.txt');
		// if (!healthSkins.contains(ClientPrefs.defaultData.healthBarSkin)) {
		// 	healthSkins.insert(0, ClientPrefs.defaultData.healthBarSkin);
		// }
		// if (!healthSkins.contains('Char Based')) {
		// 	healthSkins.insert(1, 'Char Based');
		// }
		// if (!healthSkins.contains(ClientPrefs.data.healthBarSkin)) {
		// 	ClientPrefs.data.healthBarSkin = ClientPrefs.defaultData.healthBarSkin;
		// }
		// var option:Option = new Option('Health Bar Skin:',
		// 	"How would you like your health bar to look?\nChar Based is set in the Character's json's.",
		// 	'healthBarSkin',
		// 	STRING,
		// 	healthSkins);
		// addOption(option);

		// var option:Option = new Option('Speaker Skin:',
		// 	"What speaker skin do you want to use?",
		// 	'speakerSkin',
		// 	STRING,
		// 	["Stage", "Default", "Christmas", "ABot", "ABot-Pixel"]);
		// addOption(option);

		#if desktop
		var option:Option = new Option('Volume Bop',
			"Should the speaker bop be dependant on user volume?\n\nTrue - Speakers bop the louder the overall volume is\nFalse - Speakers bop at song volume independent of user volume",
			'volumeDependantBop',
			'bool');
		addOption(option);
		#end

		// var option:Option = new Option('Show Credits',
		// 	'Uncheck this if you dont want to see the credits on song start',
		// 	'showSongCredits',
		// 	'bool');
		// addOption(option);

		// var option:Option = new Option('Dynamic Cam. Move Amount',
		// 	'The camera move depending on the note pressed using this value \nif the value is zero, it is disabled',
		// 	'extraCamMovementAmount',
		// 	INT);
		// option.scrollSpeed = 2.5;
		// option.minValue = 0;
		// option.maxValue = 100;
		// option.changeValue = 1;
		// option.decimals = 1;
		// addOption(option);

		// var option:Option = new Option('Icons Dance:',
		// 	"Combine up to 2 icon animations!",
		// 	'iconAnims',
		// 	ARRAY, 
		// 	[
		// 		'Default', 
        //         'Arrow Funk', 
        //         'GF Dance', 
        //         'Zoom In And Out', 
        //         'Bounce', 
        //         'Heartbeat', 
        //         'Spin', 
        //         'Color Flash', 
        //         'Stretch', 
        //         'Mirror Flip', 
        //         'Beat Drop', 
        //         'Color Cycle', 
        //         'Vertical Shake',
        //         'Pulse',   
        //         'Pop',        
        //         'Tilt',         
        //         'Glow',             
        //         'Disabled'
		// 	],
		// 	null,
		// 	2 
		// );
		// addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			STRING,
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Score Text Grow on Hit',
			"If unchecked, disables the Score text growing\neverytime you hit a note.",
			'scoreZoom',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			BOOL);
		addOption(option);
		option.onChange = onChangeFPSCounter;
		#end
		
		var option:Option = new Option('Pause Music:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			STRING,
			['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)']);
		addOption(option);
		option.onChange = onChangePauseMusic;
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			BOOL);
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			BOOL);
		addOption(option);

		super();
		add(notes);
		add(splashes);
		add(strums);
	}

	var notesShown:Bool = false;
	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		switch(curOption.variable)
		{
			case 'noteSkin', 'splashSkin', 'splashAlpha', 'strumSkin':
				if(!notesShown)
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = true;
				if(curOption.variable.startsWith('splash') && Math.abs(notes.members[0].y - noteY) < 25) playNoteSplashes();
				if(curOption.variable.startsWith('strum') && Math.abs(notes.members[0].y - noteY) < 25) playStrumCovers();

			default:
				if(notesShown) 
				{
					for (note in notes.members)
					{
						FlxTween.cancelTweensOf(note);
						FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
					}
				}
				notesShown = false;
		}
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote) {
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.defaultNoteSkin;
		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.reloadNote();
		note.playAnim('static');
	}

	function onChangeSplashSkin()
	{
		var skin:String = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		for (splash in splashes)
			splash.loadSplash(skin);

		playNoteSplashes();
	}

	function playNoteSplashes()
	{
		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1) rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1);

		for (splash in splashes)
		{
			splash.revive();
			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1) splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);

			var anim:String = splash.playDefaultAnim();
			splash.visible = true;
			splash.alpha = ClientPrefs.data.splashAlpha;
			
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];

			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null) {
				offsets = conf.offsets;

				minFps = conf.fps[0];
				if (minFps < 0) minFps = 0;

				maxFps = conf.fps[1];
				if (maxFps < 0) maxFps = 0;
			}

			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}

			if (splash.animation.curAnim != null) splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	var strumTime:FlxTimer;

	function playStrumCovers() {
		for (strum in strums) {
			strum.reloadCover();
			strum.showSplash = true;
			strum.visible = true;
			strum.start();
		}
		if (strumTime != null) strumTime.cancel();
		strumTime = new FlxTimer().start(0.5, function(t:FlxTimer) {
			if (strums.members.length > 0) for (strum in strums) if (strum != null) strum.end();
			strumTime = null;
		});
	}

	override function destroy()
	{
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		if (strumTime != null) strumTime.cancel();
		Note.globalRgbShaders = [];
		super.destroy();
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}
	#end

	override function closeSubState() {
		super.closeSubState();
		WindowUtils.changeTitle(WindowUtils.baseTitle + " - Visual Settings");
	}
}
