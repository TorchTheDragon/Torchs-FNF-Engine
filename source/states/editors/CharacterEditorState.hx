package states.editors;

import flixel.graphics.FlxGraphic;

import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;

import objects.Character;
import objects.HealthIcon;
import objects.Bar;
import objects.Note;

import states.editors.content.Prompt;
import states.editors.content.PsychJsonPrinter;
import backend.EditorState;
import torchsthings.utils.WindowUtils;

//class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
class CharacterEditorState extends EditorState implements PsychUIEventHandler.PsychUIEvent
{
	var character:Character;
	var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
	var cameraFollowPointer:FlxSprite;
	var isAnimateSprite:Bool = false;

	var silhouettes:FlxSpriteGroup;
	var dadPosition = FlxPoint.weak();
	var bfPosition = FlxPoint.weak();

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

	var healthBar:Bar;
	var healthIcon:HealthIcon;

	var copiedOffset:Array<Float> = [0, 0];
	var _char:String = null;
	var _goToPlayState:Bool = true;

	var anims = null;
	var animsTxt:FlxText;
	var curAnim = 0;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var UI_box:PsychUIBox;
	var UI_characterbox:PsychUIBox;

	var unsavedProgress:Bool = false;

	var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

	public function new(char:String = null, goToPlayState:Bool = true)
	{
		this._char = char;
		this._goToPlayState = goToPlayState;
		if(this._char == null) this._char = Character.DEFAULT_CHARACTER;

		super();
	}

	override function create()
	{
		WindowUtils.changeTitle(WindowUtils.baseTitle + ' - Character Editor');

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.music.stop();
		camEditor = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		loadBG();

		silhouettes = new FlxSpriteGroup();
		add(silhouettes);

		var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
		dad.antialiasing = ClientPrefs.data.antialiasing;
		dad.active = false;
		dad.offset.set(-4, 1);
		silhouettes.add(dad);

		var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
		boyfriend.antialiasing = ClientPrefs.data.antialiasing;
		boyfriend.active = false;
		boyfriend.offset.set(-6, 2);
		silhouettes.add(boyfriend);

		silhouettes.alpha = 0.25;

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);
		
		animsTxt = new FlxText(10, 32, 400, '');
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.cameras = [camHUD];

		addCharacter();

		cameraFollowPointer = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();

		healthBar = new Bar(30, FlxG.height - 75);
		healthBar.scrollFactor.set();
		healthBar.cameras = [camHUD];

		healthIcon = new HealthIcon(character.healthIcon, false, false);
		healthIcon.y = FlxG.height - 150;
		healthIcon.cameras = [camHUD];

		add(cameraFollowPointer);
		add(healthBar);
		add(healthIcon);
		add(animsTxt);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

		addHelpScreen();
		//FlxG.mouse.visible = true;
		Cursor.show();
		FlxG.camera.zoom = 1;

		makeUIMenu();

		updatePointerPos();
		updateHealthBar();
		character.finishAnimation();

		if(ClientPrefs.data.cacheOnGPU) Paths.clearUnusedMemory();

		super.create();
	}

	function addHelpScreen()
	{
		var str:Array<String> = ["CAMERA",
		"E/Q - Camera Zoom In/Out",
		"J/K/L/I - Move Camera",
		"R - Reset Camera Zoom",
		"",
		"CHARACTER",
		"Ctrl + R - Reset Current Offset",
		"Ctrl + C - Copy Current Offset",
		"Ctrl + V - Paste Copied Offset on Current Animation",
		"Ctrl + Z - Undo Last Paste or Reset",
		"W/S - Previous/Next Animation",
		"Space - Replay Animation",
		"Arrow Keys/Mouse & Right Click - Move Offset",
		"A/D - Frame Advance (Back/Forward)",
		"",
		"OTHER",
		"F12 - Toggle Silhouettes",
		"Hold Shift - Move Offsets 10x faster and Camera 4x faster",
		"Hold Control - Move camera 4x slower"];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if(txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length/2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function addCharacter(reload:Bool = false)
	{
		var pos:Int = -1;
		if(character != null)
		{
			pos = members.indexOf(character);
			remove(character);
			character.destroy();
		}

		var isPlayer = (reload ? character.isPlayer : !predictCharacterIsNotPlayer(_char));
		character = new Character(0, 0, _char, isPlayer);
		if(!reload && character.editorIsPlayer != null && isPlayer != character.editorIsPlayer)
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = (character.originalFlipX != character.isPlayer);
			if(check_player != null) check_player.checked = character.isPlayer;
		}
		character.debugMode = true;
		character.missingCharacter = false;

		if(pos > -1) insert(pos, character);
		else add(character);
		updateCharacterPositions();
		reloadAnimList();
		if(healthBar != null && healthIcon != null) updateHealthBar();
	}

	function makeUIMenu()
	{
		UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_box.scrollFactor.set();
		UI_box.cameras = [camHUD];

		UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 280, ['Animations', 'Character', 'Note Colors', 'Note Textures']);
		UI_characterbox.scrollFactor.set();
		UI_characterbox.cameras = [camHUD];
		add(UI_characterbox);
		add(UI_box);
		//boxesGroup([UI_characterbox, UI_box]);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();
		addNoteColorsUI();
		addNoteTexturesUI();

		UI_box.selectedName = 'Settings';
		UI_characterbox.selectedName = 'Character';
	}

	var ghostAlpha:Float = 0.6;
	function addGhostUI()
	{
		var tab_group = UI_box.getTab('Ghost').menu;

		//var hideGhostButton:PsychUIButton = null;
		var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
			var anim = anims[curAnim];
			if(!character.isAnimationNull())
			{
				var myAnim = anims[curAnim];
				if(!character.isAnimateAtlas)
				{
					ghost.loadGraphic(character.graphic);
					ghost.frames.frames = character.frames.frames;
					ghost.animation.copyFrom(character.animation);
					ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
					ghost.animation.pause();
				}
				else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						animateGhost = new FlxAnimate(ghost.x, ghost.y);
						animateGhost.showPivot = false;
						insert(members.indexOf(ghost), animateGhost);
						animateGhost.active = false;
					}

					if(animateGhost == null || animateGhostImage != character.imageFile)
						Paths.loadAnimateAtlas(animateGhost, character.imageFile);
					
					if(myAnim.indices != null && myAnim.indices.length > 0)
						animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					animateGhost.anim.play('anim', true, false, character.atlas.anim.curFrame);
					animateGhost.anim.pause();

					animateGhostImage = character.imageFile;
				}
				
				var spr:FlxSprite = !character.isAnimateAtlas ? ghost : animateGhost;
				if(spr != null)
				{
					spr.setPosition(character.x, character.y);
					spr.antialiasing = character.antialiasing;
					spr.flipX = character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(character.scale.x, character.scale.y);
					spr.updateHitbox();

					spr.offset.set(character.offset.x, character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
				/*hideGhostButton.active = true;
				hideGhostButton.alpha = 1;*/
				trace('created ghost image');
			}
		});

		/*hideGhostButton = new PsychUIButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
			ghost.visible = false;
			hideGhostButton.active = false;
			hideGhostButton.alpha = 0.6;
		});
		hideGhostButton.active = false;
		hideGhostButton.alpha = 0.6;*/

		var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			ghost.colorTransform.redOffset = value;
			ghost.colorTransform.greenOffset = value;
			ghost.colorTransform.blueOffset = value;
			if(animateGhost != null)
			{
				animateGhost.colorTransform.redOffset = value;
				animateGhost.colorTransform.greenOffset = value;
				animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float)
		{
			ghostAlpha = v;
			ghost.alpha = ghostAlpha;
			if(animateGhost != null) animateGhost.alpha = ghostAlpha;

		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		//tab_group.add(hideGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	var check_player:PsychUICheckBox;
	var charDropDown:PsychUIDropDownMenu;
	function addSettingsUI()
	{
		var tab_group = UI_box.getTab('Settings').menu;

		check_player = new PsychUICheckBox(10, 60, "Playable Character", 100);
		check_player.checked = character.isPlayer;
		check_player.onClick = function()
		{
			character.isPlayer = !character.isPlayer;
			character.flipX = !character.flipX;
			updateCharacterPositions();
			updatePointerPos(false);
		};

		var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", function()
		{
			addCharacter(true);
			updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function()
		{
			final _template:CharacterFile =
			{
				animations: [
					newAnim('idle', 'BF idle dance'),
					newAnim('singLEFT', 'BF NOTE LEFT0'),
					newAnim('singDOWN', 'BF NOTE DOWN0'),
					newAnim('singUP', 'BF NOTE UP0'),
					newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null,
				noteColors: {
					left: [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
					down: [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
					up: [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
					right: [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
				},
				altNoteColors: {
					left: [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
					down: [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
					up: [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
					right: [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
				},
				hasAltColors: false
			};

			character.loadCharacterFile(_template);
			character.missingCharacter = false;
			character.color = FlxColor.WHITE;
			character.alpha = 1;
			reloadAnimList();
			reloadCharacterOptions();
			updateCharacterPositions();
			updatePointerPos();
			reloadCharacterDropDown();
			updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;


		charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String)
		{
			if(intended == null || intended.length < 1) return;

			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				_char = intended;
				check_player.checked = character.isPlayer;
				addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = _char;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

	var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = UI_characterbox.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if(indicesText.length > 0)
			{
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if(indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if(ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if(Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;
	
							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if(Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;
	
							for (index in indexStart...indexEnd+1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if(!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastAnim:String = (character.animationsArray[curAnim] != null) ? character.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(character.hasAnimation(animationInputText.text))
					{
						if(!character.isAnimateAtlas) character.animation.remove(animationInputText.text);
						else @:privateAccess character.atlas.anim.animsMap.remove(animationInputText.text);
					}
					character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			character.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, character.animationsArray.indexOf(addedAnim)));
			character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			for (anim in character.animationsArray)
				if(animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if(anim.anim == character.getAnimationName()) resetAnim = true;
					if(character.hasAnimation(anim.anim))
					{
						if(!character.isAnimateAtlas) character.animation.remove(anim.anim);
						else @:privateAccess character.atlas.anim.animsMap.remove(anim.anim);
						character.animOffsets.remove(anim.anim);
						character.animationsArray.remove(anim);
					}

					if(resetAnim && character.animationsArray.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
						character.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	var imageInputText:PsychUIInputText;
	var healthIconInputText:PsychUIInputText;
	var vocalsInputText:PsychUIInputText;

	var singDurationStepper:PsychUINumericStepper;
	var scaleStepper:PsychUINumericStepper;
	var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionCameraXStepper:PsychUINumericStepper;
	var positionCameraYStepper:PsychUINumericStepper;

	var flipXCheckBox:PsychUICheckBox;
	var noAntialiasingCheckBox:PsychUICheckBox;

	var healthColorStepperR:PsychUINumericStepper;
	var healthColorStepperG:PsychUINumericStepper;
	var healthColorStepperB:PsychUINumericStepper;
	function addCharacterUI()
	{
		var tab_group = UI_characterbox.getTab('Character').menu;

		imageInputText = new PsychUIInputText(15, 30, 200, character.imageFile, 8);
		var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			var lastAnim = character.getAnimationName();
			character.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(!character.isAnimationNull()) {
				character.playAnim(lastAnim, true);
			}
		});

		var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function()
			{
				var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(healthIcon));
				character.healthColorArray[0] = coolColor.red;
				character.healthColorArray[1] = coolColor.green;
				character.healthColorArray[2] = coolColor.blue;
				updateHealthBar();
			});

		healthIconInputText = new PsychUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

		vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, character.vocalsFile != null ? character.vocalsFile : '', 8);

		singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = character.flipX;
		if(character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function() {
			character.originalFlipX = !character.originalFlipX;
			character.flipX = (character.originalFlipX != character.isPlayer);
		};

		noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		noAntialiasingCheckBox.onClick = function() {
			character.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing) {
				character.antialiasing = true;
			}
			character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character.healthColorArray[0], 0, 255, 0);
		healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character.healthColorArray[1], 0, 255, 0);
		healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon name:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 100, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 100, 'Health Bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
	}

	// HELL YEAH, I REDUCED THE STEPPER COUNT
	var noteColorStepperInsideR:PsychUINumericStepper;
	var noteColorStepperInsideG:PsychUINumericStepper;
	var noteColorStepperInsideB:PsychUINumericStepper;
	var noteColorStepperInbetweenR:PsychUINumericStepper;
	var noteColorStepperInbetweenG:PsychUINumericStepper;
	var noteColorStepperInbetweenB:PsychUINumericStepper;
	var noteColorStepperOuterR:PsychUINumericStepper;
	var noteColorStepperOuterG:PsychUINumericStepper;
	var noteColorStepperOuterB:PsychUINumericStepper;

	var noteColors:Array<Array<FlxColor>> = [
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF],
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF],
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF],
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
	];
	var noteColorsAlt:Array<Array<FlxColor>> = [
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF],
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF],
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF],
		[0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF]
	];

	var curNote:Int = 0;

	var hasAltNoteColors:PsychUICheckBox;
	var disableNoteRGB:PsychUICheckBox;
	var reloadNotes:PsychUIButton;

	var leftNoteButton:PsychUIButton;
	var downNoteButton:PsychUIButton;
	var upNoteButton:PsychUIButton;
	var rightNoteButton:PsychUIButton;
	var changeToAltColors:PsychUIButton;
	var altColors:Bool = false;

	var redText:FlxText;
	var blueText:FlxText;
	var greenText:FlxText;
	var altText:FlxText;

	var innerColorRectangle:FlxSprite;
	var inbetweenColorRectangle:FlxSprite;
	var outerColorRectangle:FlxSprite;

	var noteColorNotes:Array<Note>;
	var altNoteColorNotes:Array<Note>;

	function addNoteColorsUI() {
		var tab_group = UI_characterbox.getTab('Note Colors').menu;
		noteColorNotes = [new Note(0, 0), new Note(0, 1), new Note(0, 2), new Note(0, 3)];
		for (i => note in noteColorNotes) {
			note.y = 15;
			note.scale.set(0.5, 0.5);
			note.updateHitbox();
			note.x = 7 + (85 * i);
			switch (i) {
				case 0:
					note.rgbShader.r = character.noteColors.left[0];
					note.rgbShader.g = character.noteColors.left[1];
					note.rgbShader.b = character.noteColors.left[2];
				case 1:
					note.rgbShader.r = character.noteColors.down[0];
					note.rgbShader.g = character.noteColors.down[1];
					note.rgbShader.b = character.noteColors.down[2];
				case 2:
					note.rgbShader.r = character.noteColors.up[0];
					note.rgbShader.g = character.noteColors.up[1];
					note.rgbShader.b = character.noteColors.up[2];
				case 3:
					note.rgbShader.r = character.noteColors.right[0];
					note.rgbShader.g = character.noteColors.right[1];
					note.rgbShader.b = character.noteColors.right[2];
			}
			tab_group.add(note);
		}
		altNoteColorNotes = [new Note(0, 0), new Note(0, 1), new Note(0, 2), new Note(0, 3)];
		for (i => note in altNoteColorNotes) {
			note.y = 15;
			note.scale.set(0.5, 0.5);
			note.updateHitbox();
			note.x = 7 + (85 * i);
			switch (i) {
				case 0:
					note.rgbShader.r = character.altNoteColors.left[0];
					note.rgbShader.g = character.altNoteColors.left[1];
					note.rgbShader.b = character.altNoteColors.left[2];
				case 1:
					note.rgbShader.r = character.altNoteColors.down[0];
					note.rgbShader.g = character.altNoteColors.down[1];
					note.rgbShader.b = character.altNoteColors.down[2];
				case 2:
					note.rgbShader.r = character.altNoteColors.up[0];
					note.rgbShader.g = character.altNoteColors.up[1];
					note.rgbShader.b = character.altNoteColors.up[2];
				case 3:
					note.rgbShader.r = character.altNoteColors.right[0];
					note.rgbShader.g = character.altNoteColors.right[1];
					note.rgbShader.b = character.altNoteColors.right[2];
			}
			note.visible = false;
			tab_group.add(note);
		}

		var redY = 140;
		var greenY = 172;
		var blueY = 204;

		noteColorStepperInsideR = new PsychUINumericStepper(noteColorNotes[0].x, redY, 20, noteColors[0][0].red, 0, 255, 0);
		noteColorStepperInsideG = new PsychUINumericStepper(noteColorStepperInsideR.x + 65, redY, 20, noteColors[0][0].green, 0, 255, 0);
		noteColorStepperInsideB = new PsychUINumericStepper(noteColorStepperInsideG.x + 65, redY, 20, noteColors[0][0].blue, 0, 255, 0);
		noteColorStepperInbetweenR = new PsychUINumericStepper(noteColorNotes[0].x, greenY, 20, noteColors[0][1].red, 0, 255, 0);
		noteColorStepperInbetweenG = new PsychUINumericStepper(noteColorStepperInbetweenR.x + 65, greenY, 20, noteColors[0][1].green, 0, 255, 0);
		noteColorStepperInbetweenB = new PsychUINumericStepper(noteColorStepperInbetweenG.x + 65, greenY, 20, noteColors[0][1].blue, 0, 255, 0);
		noteColorStepperOuterR = new PsychUINumericStepper(noteColorNotes[0].x, blueY, 20, noteColors[0][2].red, 0, 255, 0);
		noteColorStepperOuterG = new PsychUINumericStepper(noteColorStepperOuterR.x + 65, blueY, 20, noteColors[0][2].green, 0, 255, 0);
		noteColorStepperOuterB = new PsychUINumericStepper(noteColorStepperOuterG.x + 65, blueY, 20, noteColors[0][2].blue, 0, 255, 0);

		var stepperArray:Array<PsychUINumericStepper> = [noteColorStepperInsideR, noteColorStepperInsideG, noteColorStepperInsideB, noteColorStepperInbetweenR, noteColorStepperInbetweenG, noteColorStepperInbetweenB, noteColorStepperOuterR, noteColorStepperOuterG, noteColorStepperOuterB];

		redText = new FlxText(noteColorNotes[0].x, redY - 12, 100, 'Inside Color:');
		innerColorRectangle = new FlxSprite(redText.x + 95, redText.y + 2).makeGraphic(100, 8, FlxColor.WHITE);
		greenText = new FlxText(noteColorNotes[0].x, greenY - 12, 100, 'Middle Color:');
		inbetweenColorRectangle = new FlxSprite(innerColorRectangle.x, greenText.y + 2).makeGraphic(100, 8, FlxColor.WHITE);
		blueText = new FlxText(noteColorNotes[0].x, blueY - 12, 100, 'Outer Color:');
		outerColorRectangle = new FlxSprite(inbetweenColorRectangle.x, blueText.y + 2).makeGraphic(100, 8, FlxColor.WHITE);

		leftNoteButton = new PsychUIButton(noteColorNotes[0].x, 100, "Left Note", function() {
			curNote = 0;
			var colors = grabColors();
			noteColorStepperInsideR.value = colors[0].red;
			noteColorStepperInsideG.value = colors[0].green;
			noteColorStepperInsideB.value = colors[0].blue;
			noteColorStepperInbetweenR.value = colors[1].red;
			noteColorStepperInbetweenG.value = colors[1].green;
			noteColorStepperInbetweenB.value = colors[1].blue;
			noteColorStepperOuterR.value = colors[2].red;
			noteColorStepperOuterG.value = colors[2].green;
			noteColorStepperOuterB.value = colors[2].blue;
			for (i in 0...stepperArray.length) {
				if (!tab_group.members.contains(stepperArray[i])) tab_group.add(stepperArray[i]);
			}
			if (!tab_group.members.contains(innerColorRectangle)) tab_group.add(innerColorRectangle);
			if (!tab_group.members.contains(inbetweenColorRectangle)) tab_group.add(inbetweenColorRectangle);
			if (!tab_group.members.contains(outerColorRectangle)) tab_group.add(outerColorRectangle);
			if (!tab_group.members.contains(redText)) tab_group.add(redText);
			if (!tab_group.members.contains(blueText)) tab_group.add(blueText);
			if (!tab_group.members.contains(greenText)) tab_group.add(greenText);
			if (!tab_group.members.contains(downNoteButton)) tab_group.add(downNoteButton); else tab_group.replace(downNoteButton, downNoteButton);
			if (!tab_group.members.contains(upNoteButton)) tab_group.add(upNoteButton); else tab_group.replace(upNoteButton, upNoteButton);
			if (!tab_group.members.contains(rightNoteButton)) tab_group.add(rightNoteButton); else tab_group.replace(rightNoteButton, rightNoteButton);
			tab_group.remove(leftNoteButton);
		});
		downNoteButton = new PsychUIButton(noteColorNotes[1].x, 100, "Down Note", function() {
			curNote = 1;
			var colors = grabColors();
			noteColorStepperInsideR.value = colors[0].red;
			noteColorStepperInsideG.value = colors[0].green;
			noteColorStepperInsideB.value = colors[0].blue;
			noteColorStepperInbetweenR.value = colors[1].red;
			noteColorStepperInbetweenG.value = colors[1].green;
			noteColorStepperInbetweenB.value = colors[1].blue;
			noteColorStepperOuterR.value = colors[2].red;
			noteColorStepperOuterG.value = colors[2].green;
			noteColorStepperOuterB.value = colors[2].blue;
			for (i in 0...stepperArray.length) {
				if (!tab_group.members.contains(stepperArray[i])) tab_group.add(stepperArray[i]);
			}
			if (!tab_group.members.contains(innerColorRectangle)) tab_group.add(innerColorRectangle);
			if (!tab_group.members.contains(inbetweenColorRectangle)) tab_group.add(inbetweenColorRectangle);
			if (!tab_group.members.contains(outerColorRectangle)) tab_group.add(outerColorRectangle);
			if (!tab_group.members.contains(redText)) tab_group.add(redText);
			if (!tab_group.members.contains(blueText)) tab_group.add(blueText);
			if (!tab_group.members.contains(greenText)) tab_group.add(greenText);
			if (!tab_group.members.contains(leftNoteButton)) tab_group.add(leftNoteButton); else tab_group.replace(leftNoteButton, leftNoteButton);
			if (!tab_group.members.contains(upNoteButton)) tab_group.add(upNoteButton); else tab_group.replace(upNoteButton, upNoteButton);
			if (!tab_group.members.contains(rightNoteButton)) tab_group.add(rightNoteButton); else tab_group.replace(rightNoteButton, rightNoteButton);
			tab_group.remove(downNoteButton);
		});
		upNoteButton = new PsychUIButton(noteColorNotes[2].x, 100, "Up Note", function() {
			curNote = 2;
			var colors = grabColors();
			noteColorStepperInsideR.value = colors[0].red;
			noteColorStepperInsideG.value = colors[0].green;
			noteColorStepperInsideB.value = colors[0].blue;
			noteColorStepperInbetweenR.value = colors[1].red;
			noteColorStepperInbetweenG.value = colors[1].green;
			noteColorStepperInbetweenB.value = colors[1].blue;
			noteColorStepperOuterR.value = colors[2].red;
			noteColorStepperOuterG.value = colors[2].green;
			noteColorStepperOuterB.value = colors[2].blue;
			for (i in 0...stepperArray.length) {
				if (!tab_group.members.contains(stepperArray[i])) tab_group.add(stepperArray[i]);
			}
			if (!tab_group.members.contains(innerColorRectangle)) tab_group.add(innerColorRectangle);
			if (!tab_group.members.contains(inbetweenColorRectangle)) tab_group.add(inbetweenColorRectangle);
			if (!tab_group.members.contains(outerColorRectangle)) tab_group.add(outerColorRectangle);
			if (!tab_group.members.contains(redText)) tab_group.add(redText);
			if (!tab_group.members.contains(blueText)) tab_group.add(blueText);
			if (!tab_group.members.contains(greenText)) tab_group.add(greenText);
			if (!tab_group.members.contains(leftNoteButton)) tab_group.add(leftNoteButton); else tab_group.replace(leftNoteButton, leftNoteButton);
			if (!tab_group.members.contains(downNoteButton)) tab_group.add(downNoteButton); else tab_group.replace(downNoteButton, downNoteButton);
			if (!tab_group.members.contains(rightNoteButton)) tab_group.add(rightNoteButton); else tab_group.replace(rightNoteButton, rightNoteButton);
			tab_group.remove(upNoteButton);
		});
		rightNoteButton = new PsychUIButton(noteColorNotes[3].x, 100, "Right Note", function() {
			curNote = 3;
			var colors = grabColors();
			noteColorStepperInsideR.value = colors[0].red;
			noteColorStepperInsideG.value = colors[0].green;
			noteColorStepperInsideB.value = colors[0].blue;
			noteColorStepperInbetweenR.value = colors[1].red;
			noteColorStepperInbetweenG.value = colors[1].green;
			noteColorStepperInbetweenB.value = colors[1].blue;
			noteColorStepperOuterR.value = colors[2].red;
			noteColorStepperOuterG.value = colors[2].green;
			noteColorStepperOuterB.value = colors[2].blue;
			for (i in 0...stepperArray.length) {
				if (!tab_group.members.contains(stepperArray[i])) tab_group.add(stepperArray[i]);
			}
			if (!tab_group.members.contains(innerColorRectangle)) tab_group.add(innerColorRectangle);
			if (!tab_group.members.contains(inbetweenColorRectangle)) tab_group.add(inbetweenColorRectangle);
			if (!tab_group.members.contains(outerColorRectangle)) tab_group.add(outerColorRectangle);
			if (!tab_group.members.contains(redText)) tab_group.add(redText);
			if (!tab_group.members.contains(blueText)) tab_group.add(blueText);
			if (!tab_group.members.contains(greenText)) tab_group.add(greenText);
			if (!tab_group.members.contains(leftNoteButton)) tab_group.add(leftNoteButton); else tab_group.replace(leftNoteButton, leftNoteButton);
			if (!tab_group.members.contains(downNoteButton)) tab_group.add(downNoteButton); else tab_group.replace(downNoteButton, downNoteButton);
			if (!tab_group.members.contains(upNoteButton)) tab_group.add(upNoteButton); else tab_group.replace(upNoteButton, upNoteButton);
			tab_group.remove(rightNoteButton);
		});

		altText = new FlxText(rightNoteButton.x - 50, rightNoteButton.y + 24, 150, "Alt Colors Selected: false");
		changeToAltColors = new PsychUIButton(altText.x, altText.y + 12, "Switch Colors", function() {
			altColors = !altColors;
			altButton();
		});

		hasAltNoteColors = new PsychUICheckBox(altText.x, changeToAltColors.y + 24, "Has Alt Note Colors?", 150);
		hasAltNoteColors.onClick = function() {character.hasAltColors = hasAltNoteColors.checked;};
		
		reloadNotes = new PsychUIButton(noteColorNotes[0].x, 235, "Reload Notes", function() {
			var allNotes:Array<Note> = [];
			for (note in noteColorNotes) {
				allNotes.push(note);
			}
			for (note in altNoteColorNotes) {
				allNotes.push(note);
			}

			for (note in allNotes) {
				note.rgbShader.enabled = !character.disableNoteRGB; // Yeah yeah, I know I am swapping it, but if "disableNoteRGB" is true, then if I didn't swap it, the notes would be showing the RGB shader in the preview
				//trace(Paths.fileExists('images/' + character.noteSkin + ".png", IMAGE, false, character.noteSkinLib));
				if (character.useNoteSkin && Paths.fileExists('images/' + character.noteSkin + ".png", IMAGE, false, character.noteSkinLib)) {
					reloadNote(note);
				}
			}

			updateAllNotes();
		});

		disableNoteRGB = new PsychUICheckBox(leftNoteButton.x + 85, 239, "No Note RGB?", 75);
		disableNoteRGB.onClick = function() {
			character.disableNoteRGB = disableNoteRGB.checked;
		};
		
		tab_group.add(altText);
		tab_group.add(changeToAltColors);
		tab_group.add(hasAltNoteColors);
		tab_group.add(leftNoteButton);
		tab_group.add(downNoteButton);
		tab_group.add(upNoteButton);
		tab_group.add(rightNoteButton);
		tab_group.add(disableNoteRGB);
		tab_group.add(reloadNotes);

		//inputTextsGroup([charNoteSkin, charNoteSkinLib]);
		//numericSteppersGroup(leftColorSteppers);
		//numericSteppersGroup(downColorSteppers);
		//numericSteppersGroup(upColorSteppers);
		//numericSteppersGroup(rightColorSteppers);
		//buttonsGroup([reloadNotes, changeToAltColors, rightNoteButton, upNoteButton, downNoteButton, leftNoteButton]);
		//checkBoxesGroup([usingNoteSkin, disableNoteRGB, hasAltNoteColors]);
		//inputTexts.add(charNoteSkin);
		//inputTexts.add(charNoteSkinLib);
	}

	var noteSkinText:FlxText;
	var charNoteSkin:PsychUIInputText;
	var noteSkinLibText:FlxText;
	var charNoteSkinLib:PsychUIInputText;
	var usingNoteSkin:PsychUICheckBox;
	var usePixelSpecific:PsychUICheckBox;

	function addNoteTexturesUI() {
		var tab_group = UI_characterbox.getTab('Note Textures').menu;
		noteSkinText = new FlxText(10, 10, 150, "Note Skin:");
		charNoteSkin = new PsychUIInputText(noteSkinText.x, noteSkinText.y + 12, 150, character.noteSkin != null ? character.noteSkin : '', 8);
		noteSkinLibText = new FlxText(charNoteSkin.x, charNoteSkin.y + 18, 150, "Note Skin Library:");
		charNoteSkinLib = new PsychUIInputText(noteSkinLibText.x, noteSkinLibText.y + 12, 150, character.noteSkinLib != null ? character.noteSkinLib : '', 8);

		usingNoteSkin = new PsychUICheckBox(10, 240, "Custom Note Skin?", 150);
		usingNoteSkin.onClick = function() {
			character.useNoteSkin = usingNoteSkin.checked;
		};

		tab_group.add(noteSkinText);
		tab_group.add(charNoteSkin);
		tab_group.add(noteSkinLibText);
		tab_group.add(charNoteSkinLib);
		tab_group.add(usingNoteSkin);
	}

	function altButton() {
		altText.text = "Alt Colors Selected: " + altColors;
		for(note in noteColorNotes) note.visible = !altColors;
		for(note in altNoteColorNotes) note.visible = altColors;

		updateAllNotes();

		noteColorStepperInsideR.value = altColors ? noteColorsAlt[curNote][0].red : noteColors[curNote][0].red;
		noteColorStepperInsideG.value = altColors ? noteColorsAlt[curNote][0].green : noteColors[curNote][0].green;
		noteColorStepperInsideB.value = altColors ? noteColorsAlt[curNote][0].blue : noteColors[curNote][0].blue;
		noteColorStepperInbetweenR.value = altColors ? noteColorsAlt[curNote][1].red : noteColors[curNote][1].red;
		noteColorStepperInbetweenG.value = altColors ? noteColorsAlt[curNote][1].green : noteColors[curNote][1].green;
		noteColorStepperInbetweenB.value = altColors ? noteColorsAlt[curNote][1].blue : noteColors[curNote][1].blue;
		noteColorStepperOuterR.value = altColors ? noteColorsAlt[curNote][2].red : noteColors[curNote][2].red;
		noteColorStepperOuterG.value = altColors ? noteColorsAlt[curNote][2].green : noteColors[curNote][2].green;
		noteColorStepperOuterB.value = altColors ? noteColorsAlt[curNote][2].blue : noteColors[curNote][2].blue;
		updateRectangles();
	}

	function updateRectangles() {
		innerColorRectangle.color = altColors ? noteColorsAlt[curNote][0] : noteColors[curNote][0];
		inbetweenColorRectangle.color = altColors ? noteColorsAlt[curNote][1] : noteColors[curNote][1];
		outerColorRectangle.color = altColors ? noteColorsAlt[curNote][2] : noteColors[curNote][2];
	}

	function grabColors():Array<FlxColor> {
		switch (curNote) {
			case 0:
				return altColors ? character.altNoteColors.left : character.noteColors.left;
			case 1:
				return altColors ? character.altNoteColors.down : character.noteColors.down;
			case 2:
				return altColors ? character.altNoteColors.up : character.noteColors.up;
			case 3:
				return altColors ? character.altNoteColors.right : character.noteColors.right;
			default:
				return [0xffffffff, 0xffffffff, 0xffffffff];
		}
	}

	function returnColor(?place:String):FlxColor {
		if (curNote < 0) curNote = 0; else if (curNote > 3) curNote = 3;
		var innerColor:FlxColor = FlxColor.fromRGB(Std.int(noteColorStepperInsideR.value), Std.int(noteColorStepperInsideG.value), Std.int(noteColorStepperInsideB.value));
		var inbetweenColor:FlxColor = FlxColor.fromRGB(Std.int(noteColorStepperInbetweenR.value), Std.int(noteColorStepperInbetweenG.value), Std.int(noteColorStepperInbetweenB.value));
		var outerColor:FlxColor = FlxColor.fromRGB(Std.int(noteColorStepperOuterR.value), Std.int(noteColorStepperOuterG.value), Std.int(noteColorStepperOuterB.value));

		altColors ? noteColorsAlt[curNote][0] = innerColor : noteColors[curNote][0] = innerColor;
		altColors ? noteColorsAlt[curNote][1] = inbetweenColor : noteColors[curNote][1] = inbetweenColor;
		altColors ? noteColorsAlt[curNote][2] = outerColor : noteColors[curNote][2] = outerColor;

		switch (place.toLowerCase()) {
			case 'outer' | 'outside' | 'out':
				return altColors ? noteColorsAlt[curNote][2] : noteColors[curNote][2];
			case 'mid' | 'middle' | 'inbetween':
				return altColors ? noteColorsAlt[curNote][1] : noteColors[curNote][1];
			case 'inside' | 'in' | 'inner':
				return altColors ? noteColorsAlt[curNote][0] : noteColors[curNote][0];
			default:
				return altColors ? noteColorsAlt[curNote][0] : noteColors[curNote][0];
		}
	}

	public function UIEvent(id:String, sender:Dynamic) {
		//trace(id, sender);
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT)
		{
			if(sender == healthIconInputText) {
				var lastIcon = healthIcon.getCharacter();
				healthIcon.changeIcon(healthIconInputText.text, false);
				character.healthIcon = healthIconInputText.text;
				if(lastIcon != healthIcon.getCharacter()) updatePresence();
				unsavedProgress = true;
			} else if (sender == vocalsInputText) {
				character.vocalsFile = vocalsInputText.text;
				unsavedProgress = true;
			} else if (sender == imageInputText) {
				character.imageFile = imageInputText.text;
				unsavedProgress = true;
			} else if (sender == charNoteSkin) {
				character.noteSkin = charNoteSkin.text;
				unsavedProgress = true;
			} else if (sender == charNoteSkinLib) {
				character.noteSkinLib = charNoteSkinLib.text;
				unsavedProgress = true;
			}
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT)
		{
			if (sender == scaleStepper) {
				reloadCharacterImage();
				character.jsonScale = sender.value;
				character.scale.set(character.jsonScale, character.jsonScale);
				character.updateHitbox();
				updatePointerPos(false);
				unsavedProgress = true;
			} else if(sender == positionXStepper) {
				character.positionArray[0] = positionXStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			} else if(sender == positionYStepper) {
				character.positionArray[1] = positionYStepper.value;
				updateCharacterPositions();
				unsavedProgress = true;
			} else if(sender == singDurationStepper) {
				character.singDuration = singDurationStepper.value;
				unsavedProgress = true;
			} else if(sender == positionCameraXStepper) {
				character.cameraPosition[0] = positionCameraXStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			} else if(sender == positionCameraYStepper) {
				character.cameraPosition[1] = positionCameraYStepper.value;
				updatePointerPos();
				unsavedProgress = true;
			} else if(sender == healthColorStepperR) {
				character.healthColorArray[0] = Math.round(healthColorStepperR.value);
				updateHealthBar();
				unsavedProgress = true;
			} else if(sender == healthColorStepperG) {
				character.healthColorArray[1] = Math.round(healthColorStepperG.value);
				updateHealthBar();
				unsavedProgress = true;
			} else if(sender == healthColorStepperB) {
				character.healthColorArray[2] = Math.round(healthColorStepperB.value);
				updateHealthBar();
				unsavedProgress = true;
			} else if (sender == noteColorStepperInsideR || sender == noteColorStepperInsideG || sender == noteColorStepperInsideB || sender == noteColorStepperInbetweenR || sender == noteColorStepperInbetweenG || sender == noteColorStepperInbetweenB || sender == noteColorStepperOuterR || sender == noteColorStepperOuterG || sender == noteColorStepperOuterB) {
				var colArray = [returnColor('inside'), returnColor('middle'), returnColor('outer')];
				updateRectangles();
				switch (curNote) {
					case 0:
						altColors ? character.altNoteColors.left = colArray : character.noteColors.left = colArray;
						updateLeftNote();
					case 1:
						altColors ? character.altNoteColors.down = colArray : character.noteColors.down = colArray;
						updateDownNote();
					case 2:
						altColors ? character.altNoteColors.up = colArray : character.noteColors.up = colArray;
						updateUpNote();
					case 3:
						altColors ? character.altNoteColors.right = colArray : character.noteColors.right = colArray;
						updateRightNote();
				}
				unsavedProgress = true;
			}
		}
	}

	function updateAllNotes() {
		for (note in noteColorNotes) {
			reloadNote(note);
			if (note.shader == null && character.disableNoteRGB == false) note.shader = note.rgbShader.parent.shader;
		}
		for (note in altNoteColorNotes) {
			reloadNote(note);
			if (note.shader == null && character.disableNoteRGB == false) note.shader = note.rgbShader.parent.shader;
		}

		updateLeftNote();
		updateDownNote();
		updateUpNote();
		updateRightNote();
	}

	function reloadNote(note:Note) {
		note.reloadNote(character.noteSkin, character.noteSkinLib);
		note.scale.set(0.5, 0.5);
		note.updateHitbox();
	}

	function updateLeftNote() {
		var noteShader = altColors ? altNoteColorNotes[0].rgbShader : noteColorNotes[0].rgbShader;
		noteShader.r = altColors ? character.altNoteColors.left[0] : character.noteColors.left[0];
		noteShader.g = altColors ? character.altNoteColors.left[1] : character.noteColors.left[1];
		noteShader.b = altColors ? character.altNoteColors.left[2] : character.noteColors.left[2];
	}

	function updateDownNote() {
		var noteShader = altColors ? altNoteColorNotes[1].rgbShader : noteColorNotes[1].rgbShader;
		noteShader.r = altColors ? character.altNoteColors.down[0] : character.noteColors.down[0];
		noteShader.g = altColors ? character.altNoteColors.down[1] : character.noteColors.down[1];
		noteShader.b = altColors ? character.altNoteColors.down[2] : character.noteColors.down[2];
	}

	function updateUpNote() {
		var noteShader = altColors ? altNoteColorNotes[2].rgbShader : noteColorNotes[2].rgbShader;
		noteShader.r = altColors ? character.altNoteColors.up[0] : character.noteColors.up[0];
		noteShader.g = altColors ? character.altNoteColors.up[1] : character.noteColors.up[1];
		noteShader.b = altColors ? character.altNoteColors.up[2] : character.noteColors.up[2];
	}

	function updateRightNote() {
		var noteShader = altColors ? altNoteColorNotes[3].rgbShader : noteColorNotes[3].rgbShader;
		noteShader.r = altColors ? character.altNoteColors.right[0] : character.noteColors.right[0];
		noteShader.g = altColors ? character.altNoteColors.right[1] : character.noteColors.right[1];
		noteShader.b = altColors ? character.altNoteColors.right[2] : character.noteColors.right[2];
	}

	function reloadCharacterImage()
	{
		var lastAnim:String = character.getAnimationName();
		var anims:Array<AnimArray> = character.animationsArray.copy();

		character.atlas = FlxDestroyUtil.destroy(character.atlas);
		character.isAnimateAtlas = false;
		character.color = FlxColor.WHITE;
		character.alpha = 1;

		if(Paths.fileExists('images/' + character.imageFile + '/Animation.json', TEXT))
		{
			character.atlas = new FlxAnimate();
			character.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(character.atlas, character.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${character.imageFile}: $e');
			}
			character.isAnimateAtlas = true;
		}
		else
		{
			character.frames = Paths.getMultiAtlas(character.imageFile.split(','));
		}

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if(anims.length > 0)
		{
			if(lastAnim != '') character.playAnim(lastAnim, true);
			else character.dance();
		}
	}

	function reloadCharacterOptions() {
		if(UI_characterbox == null) return;

		check_player.checked = character.isPlayer;
		imageInputText.text = character.imageFile;
		healthIconInputText.text = character.healthIcon;
		vocalsInputText.text = character.vocalsFile != null ? character.vocalsFile : '';
		singDurationStepper.value = character.singDuration;
		scaleStepper.value = character.jsonScale;
		flipXCheckBox.checked = character.originalFlipX;
		noAntialiasingCheckBox.checked = character.noAntialiasing;
		positionXStepper.value = character.positionArray[0];
		positionYStepper.value = character.positionArray[1];
		positionCameraXStepper.value = character.cameraPosition[0];
		positionCameraYStepper.value = character.cameraPosition[1];
		altColors = false;
		disableNoteRGB.checked = character.disableNoteRGB;
		usingNoteSkin.checked = character.useNoteSkin;
		charNoteSkin.text = character.noteSkin;
		charNoteSkinLib.text = character.noteSkinLib;
		reloadAnimationDropDown();
		updateHealthBar();
		updateAllNotes();
		setNoteColorVals();
		altButton();
	}

	function setNoteColorVals() {
		var colors = [character.noteColors.left, character.noteColors.down, character.noteColors.up, character.noteColors.right];
		noteColors[0] = colors[0];
		noteColors[1] = colors[1];
		noteColors[2] = colors[2];
		noteColors[3] = colors[3];
		var colorsAlt = [character.altNoteColors.left, character.altNoteColors.down, character.altNoteColors.up, character.altNoteColors.right];
		noteColorsAlt[0] = colorsAlt[0];
		noteColorsAlt[1] = colorsAlt[1];
		noteColorsAlt[2] = colorsAlt[2];
		noteColorsAlt[3] = colorsAlt[3];

		noteColorStepperInsideR.value = noteColors[0][0].red;
		noteColorStepperInsideG.value = noteColors[0][0].green;
		noteColorStepperInsideB.value = noteColors[0][0].blue;
		noteColorStepperInbetweenR.value = noteColors[0][1].red;
		noteColorStepperInbetweenG.value = noteColors[0][1].green;
		noteColorStepperInbetweenB.value = noteColors[0][1].blue;
		noteColorStepperOuterR.value = noteColors[0][2].red;
		noteColorStepperOuterG.value = noteColors[0][2].green;
		noteColorStepperOuterB.value = noteColors[0][2].blue;
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;
	var firstColorUpdate:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Only to update the initial colors.
		if (!firstColorUpdate) {
			returnColor();
		}

		updateRectangles();

		if(PsychUIInputText.focusOn != null)
		{
			ClientPrefs.toggleVolumeKeys(false);
			return;
		}
		ClientPrefs.toggleVolumeKeys(true);

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
		}
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
			if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
		}

		if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

		// CHARACTER CONTROLS
		var changedAnim:Bool = false;
		if(anims.length > 1)
		{
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

			if(changedAnim)
			{
				undoOffsets = null;
				curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
				character.playAnim(anims[curAnim].anim, true);
				updateText();
			}
		}

		var changedOffset = false;
		var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
		var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
		if(moveKeysP.contains(true))
		{
			character.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
			character.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
			changedOffset = true;
		}

		if(moveKeys.contains(true))
		{
			holdingArrowsTime += elapsed;
			if(holdingArrowsTime > 0.6)
			{
				holdingArrowsElapsed += elapsed;
				while(holdingArrowsElapsed > (1/60))
				{
					character.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
					character.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
					holdingArrowsElapsed -= (1/60);
					changedOffset = true;
				}
			}
		}
		else holdingArrowsTime = 0;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			character.offset.x -= FlxG.mouse.deltaScreenX;
			character.offset.y -= FlxG.mouse.deltaScreenY;
			changedOffset = true;
		}

		if(FlxG.keys.pressed.CONTROL)
		{
			if(FlxG.keys.justPressed.C)
			{
				copiedOffset[0] = character.offset.x;
				copiedOffset[1] = character.offset.y;
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.V)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.x = copiedOffset[0];
				character.offset.y = copiedOffset[1];
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.R)
			{
				undoOffsets = [character.offset.x, character.offset.y];
				character.offset.set(0, 0);
				changedOffset = true;
			}
			else if(FlxG.keys.justPressed.Z && undoOffsets != null)
			{
				character.offset.x = undoOffsets[0];
				character.offset.y = undoOffsets[1];
				changedOffset = true;
			}
		}

		var anim = anims[curAnim];
		if(changedOffset && anim != null && anim.offsets != null)
		{
			anim.offsets[0] = Std.int(character.offset.x);
			anim.offsets[1] = Std.int(character.offset.y);

			character.addOffset(anim.anim, character.offset.x, character.offset.y);
			updateText();
		}

		var txt = 'ERROR: No Animation Found';
		var clr = FlxColor.RED;
		if(!character.isAnimationNull())
		{
			if(FlxG.keys.pressed.A || FlxG.keys.pressed.D)
			{
				holdingFrameTime += elapsed;
				if(holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
			}
			else holdingFrameTime = 0;

			if(FlxG.keys.justPressed.SPACE)
				character.playAnim(character.getAnimationName(), true);

			var frames:Int = -1;
			var length:Int = -1;
			if(!character.isAnimateAtlas && character.animation.curAnim != null)
			{
				frames = character.animation.curAnim.curFrame;
				length = character.animation.curAnim.numFrames;
			}
			else if(character.isAnimateAtlas && character.atlas.anim != null)
			{
				frames = character.atlas.anim.curFrame;
				length = character.atlas.anim.length;
			}

			if(length >= 0)
			{
				if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
				{
					var isLeft = false;
					if((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
					character.animPaused = true;
	
					if(holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
					{
						frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length-1);
						if(!character.isAnimateAtlas) character.animation.curAnim.curFrame = frames;
						else character.atlas.anim.curFrame = frames;
						holdingFrameElapsed -= 0.1;
					}
				}
	
				txt = 'Frames: ( $frames / ${length-1} )';
				//if(character.animation.curAnim.paused) txt += ' - PAUSED';
				clr = FlxColor.WHITE;
			}
		}
		if(txt != frameAdvanceText.text) frameAdvanceText.text = txt;
		frameAdvanceText.color = clr;

		// OTHER CONTROLS
		if(FlxG.keys.justPressed.F12)
			silhouettes.visible = !silhouettes.visible;

		if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
		{
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}
		else if(FlxG.keys.justPressed.ESCAPE)
		{
			if(!_goToPlayState)
			{
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new states.editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else openSubState(new ExitConfirmationPrompt());
			}
			else
			{
				//FlxG.mouse.visible = false;
				Cursor.hide();
				MusicBeatState.switchState(new PlayState());
			}
			return;
		}
	}

	final assetFolder = 'week1';  //load from assets/week1/
	inline function loadBG()
	{
		var lastLoaded = Paths.currentLevel;
		Paths.currentLevel = assetFolder;

		/////////////
		// bg data //
		/////////////
		#if !BASE_GAME_FILES
		camEditor.bgColor = 0xFF666666;
		#else
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);
		#end

		dadPosition.set(100, 100);
		bfPosition.set(770, 100);
		/////////////

		Paths.currentLevel = lastLoaded;
	}

	inline function updatePointerPos(?snap:Bool = true)
	{
		if(character == null || cameraFollowPointer == null) return;

		var offX:Float = 0;
		var offY:Float = 0;
		if(!character.isPlayer)
		{
			offX = character.getMidpoint().x + 150 + character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		else
		{
			offX = character.getMidpoint().x - 100 - character.cameraPosition[0];
			offY = character.getMidpoint().y - 100 + character.cameraPosition[1];
		}
		cameraFollowPointer.setPosition(offX, offY);

		if(snap)
		{
			FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width/2;
			FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height/2;
		}
	}

	inline function updateHealthBar()
	{
		healthColorStepperR.value = character.healthColorArray[0];
		healthColorStepperG.value = character.healthColorArray[1];
		healthColorStepperB.value = character.healthColorArray[2];
		healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
		healthIcon.changeIcon(character.healthIcon, false);
		updatePresence();
	}

	inline function updatePresence() {
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
		#end
	}

	inline function reloadAnimList()
	{
		anims = character.animationsArray;
		if(anims.length > 0) character.playAnim(anims[0].anim, true);
		curAnim = 0;

		updateText();
		if(animationDropDown != null) reloadAnimationDropDown();
	}

	inline function updateText()
	{
		animsTxt.removeFormat(selectedFormat);

		var intendText:String = '';
		for (num => anim in anims)
		{
			if(num > 0) intendText += '\n';

			if(num == curAnim)
			{
				var n:Int = intendText.length;
				intendText += anim.anim + ": " + anim.offsets;
				animsTxt.addFormat(selectedFormat, n, intendText.length);
			}
			else intendText += anim.anim + ": " + anim.offsets;
		}
		animsTxt.text = intendText;
	}

	inline function updateCharacterPositions()
	{
		if((character != null && !character.isPlayer) || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPosition.x, dadPosition.y);
		else character.setPosition(bfPosition.x, bfPosition.y);

		character.x += character.positionArray[0];
		character.y += character.positionArray[1];
		updatePointerPos(false);
	}

	inline function predictCharacterIsNotPlayer(name:String)
	{
		return (name != 'bf' && !name.startsWith('bf-') && !name.endsWith('-player') && !name.endsWith('-playable') && !name.endsWith('-dead')) ||
				name.endsWith('-opponent') || name.startsWith('gf-') || name.endsWith('-gf') || name == 'gf';
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if(!character.isAnimateAtlas)
		{
			if(indices != null && indices.length > 0)
				character.animation.addByIndices(anim, name, indices, "", fps, loop);
			else
				character.animation.addByPrefix(anim, name, fps, loop);
		}
		else
		{
			if(indices != null && indices.length > 0)
				character.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
			else
				character.atlas.anim.addBySymbol(anim, name, fps, loop);
		}

		if(!character.hasAnimation(anim))
			character.addOffset(anim, 0, 0);
	}

	inline function newAnim(anim:String, name:String):AnimArray
	{
		return {
			offsets: [0, 0],
			loop: false,
			fps: 24,
			anim: anim,
			indices: [],
			name: name
		};
	}

	var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = _char;
	}

	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in anims) animList.push(anim.anim);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	// save
	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		if(_file != null) return;

		var json:Dynamic = {
			"animations": character.animationsArray,
			"image": character.imageFile,
			"scale": character.jsonScale,
			"sing_duration": character.singDuration,
			"healthicon": character.healthIcon,

			"position":	character.positionArray,
			"camera_position": character.cameraPosition,

			"flip_x": character.originalFlipX,
			"no_antialiasing": character.noAntialiasing,
			"healthbar_colors": character.healthColorArray,
			"vocals_file": character.vocalsFile,
			"_editor_isPlayer": character.isPlayer,

			"noteColors": {
				"left": character.noteColors.left,
				"down": character.noteColors.down,
				"up": character.noteColors.up,
				"right": character.noteColors.right
			},
			"altNoteColors": {
				"left": character.altNoteColors.left,
				"down": character.altNoteColors.down,
				"up": character.altNoteColors.up,
				"right": character.altNoteColors.right
			},
			"hasAltColors": character.hasAltColors,
			"noteSkin": character.noteSkin,
			"noteSkinLib": character.noteSkinLib,
			"disableNoteRGB": character.disableNoteRGB,
			"useNoteSkin": character.useNoteSkin
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices']);

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$_char.json');
		}
	}
}