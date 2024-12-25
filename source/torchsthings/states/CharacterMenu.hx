package torchsthings.states;

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end
import objects.Character.Character;
import objects.HealthIcon.HealthIcon;
import torchsthings.objects.CharacterInfoCard;
import backend.Highscore;
import backend.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.utils.Assets;
import openfl.net.FileReference;
#if debug
import flixel.ui.FlxButton;
import flixel.addons.ui.*;
#end

// To add these libraries below, just do "haxelib install torchsfunctions"
import torchsfunctions.functions.KeyboardTools;
import torchsfunctions.functions.ArrayTools;
import torchsfunctions.functions.MathTools;

import states.*;
import Math;
using StringTools;

class CharacterMenu extends MusicBeatState{
    /*
        This variable allows you to specify certain weeks/songs that should only use 
        specific character menus instead of the default "all characters" menu.

        It is an array of sub-arrays, where each sub-array has two elements:
        1. The week/song name as a string 
        2. An integer specifying which menu to use:
            0 = All characters (default)
            1 = BF and GF only
            2 = Enemy and BF only 
            3 = Enemy and GF only
            4 = BF only
            5 = GF only
            6 = Enemy only

        For example:
        [['milf', 2], ['guns', 1]]
        This makes 'milf' use the Enemy + BF menu, and 'guns' use the BF + GF menu.
    */
    public static var specificCharMenus:Array<Array<Dynamic>> = [['tutorial', 1], ['stress', 2]];

    // Disables these songs from being able to use the character menu
    public static var blacklistedSongs:Array<String> = ['test'];

    // Songs using a pixel stage
    public static var pixelSongs:Array<String> = ['senpai', 'roses', 'thorns'];

    // Just a check to see if the character menu was used
    public static var usedCharMenu:Bool = false;

    // The Non-Pixel characters, used for the normal stages
    var standardCharacters:Array<Array<String>> = [
        // BF characters
        [PlayState.SONG.player1, 'pico-player', 'torch', 'bf-pixel', 'axylus-playable'],
        // GF characters
        [PlayState.SONG.gfVersion],
        // Enemy characters
        [PlayState.SONG.player2, 'tankman', 'axylus'] 
    ];

    // The Pixel characters, used for the pixel stages
    var pixelCharacters:Array<Array<String>> = [
        // BF characters
        [PlayState.SONG.player1], 
        // GF characters
        [PlayState.SONG.gfVersion], 
        // Enemy characters
        [PlayState.SONG.player2] 
    ];

    // Do not remove these variables, used to grab ALL characters in the build
    var characterList:Array<String> = [];
    var unlistedCharacters:Array<String> = [ // Put specific mod characters here (that are not in the "characterList.txt" file)
        "darnell",
        "nene", 
        'torch'
    ]; // PLEASE KEEP TRACK IF YOU ADD NEW CHARACTERS, IT GETS ANNOYING WHEN SOMETHING CRASHES HERE BECAUSE A CHARACTER WASN'T ADDED TO THIS LIST HERE

    // This blocks specific characters depending on the song
    // Order is ['Song Name', ["Each", "Character"]]
    var blockedCharactersPerSong:Array<Array<Dynamic>> = [
    ];

    // Unlocks chars based on if an achievement has been unlocked or not, can be null if you want the character to still have a locked description (not implemented) but be unlocked by other methods
    /*
    Slot 1: Character
    Slot 2: Achievement Needed, can be null
    Slot 3: Description to unlock character
    */
    var charsToUnlock:Array<Array<String>> = [
        ['torch', null, "Idk how to unlock this guy..."],
        ['pico-player', 'week3_nomiss', "Beat week 3 without a single miss"]
    ];

    // Default Unlocked Characters
    var defaultUnlocked:Array<String> = [
        'bf', 
        'bf-car', 
        'bf-christmas', 
        'bf-pixel'
    ];

    // Character Scaling
    var charScale:Float = 0.6;
    /*
    // Character Scaling [Default, Pixel]
    var charScales:Array<Float> = [0.6, 4.125];
    */

    // You can edit charYOffset and tweenTime to change the height after the tween, and how fast the tween is
    var charYOffset:Float = 600;
    var tweenTime:Float = 0.25;

    // Changes what folder the assets are loaded from.
    var daFolder:String = 'torchs_assets'; 
    // Changes what color the characters appear as when locked if the option to view locked characters is enabled.
    var lockedColor:FlxColor = 0xFF1B1B1B; 

    // Below this are all the variables you shouldn't touch

    // Icons for all the characters
    var bfIcon:HealthIcon;
    var gfIcon:HealthIcon;
    var enemyIcon:HealthIcon;

    // Arrays of all the selectable chars
    var bfImageArray:Array<Character> = [];
    var gfImageArray:Array<Character> = [];
    var enemyImageArray:Array<Character> = [];

    // Character Tween Values Values
    var enemyDestTweens:Array<FlxTween> = [null];
    var gfDestTweens:Array<FlxTween> = [null];
    var bfDestTweens:Array<FlxTween> = [null];
    var alphaTweens:Array<Array<FlxTween>> = [[null], [null], [null]];
    var colorTweens:Array<FlxTween> = [null];

    // These three variables for Colors, Offsets, and Names will be removed when I implement the json files
    // The colors for the background behind the characters
    // REMINDER, DO NOT MAKE IT A COLOR LIKE 0xFF00ABC5, MAKE IT A # INSTEAD, SO LIKE #00ABC5
    // By default, it is located in "assets/torchs_assets/data/charMenu/characterColors.txt"
    var allColors:Array<Array<String>> = [];

    // Offsets for the characters to make them appear in a more correct place
    // By default, it is located in "assets/torchs_assets/data/charMenu/characterOffsets.txt"
    var allOffsets:Array<Array<String>> = [];

    // THESE NAMES AREN'T IN USE RIGHT NOW, THOUGH GO AHEAD AND ADD YOUR CHARACTER AND ITS NAME AHEAD OF TIME IF YOU WANT
    // The names of the characters (Not Implemented)
    // By default, it is located in "assets/torchs_assets/data/charMenu/characterNames.txt"
    var characterNames:Array<Array<String>> = [];

    // Variables that contain the main parts of the selections
    var alreadySelected:Bool = false;
    var selector:FlxText;
    public static var fromFreeplay:Bool = false;
    public static var playstateDiff:Int = -1;
    public static var pixelSong:Bool = false;
    var characterLocks:Array<Array<String>> = [];
    var charIndex = [];
    
    // Variables to determine which char is the selected one
    var selectedBF:Int = 0;
    var selectedGF:Int = 0;
    var selectedEnemy:Int = 0;
    var selectedColumn:String = 'enemy'; // Just used to determine if Enemy, GF, or BF is selected

    // 3 Characters, 3 Background Images
    var leftThirdBG:FlxSprite;
    var middleThirdBG:FlxSprite;
    var rightThirdBG:FlxSprite;
    // 2 Characters, 2 Background Images
    var leftHalfBG:FlxSprite;
    var rightHalfBG:FlxSprite;
    // 1 Character, 1 Background Image
    var fullBG:FlxSprite;
    // Bars over and under the background images
    var bgOverlay:FlxSprite;

    // Used for the 'new' function to determine what peeps are availible for picking, it also shouldn't matter the position you put them in
    private var charactersToChooseFrom:Array<String> = ['bf', 'gf', 'enemy'];

    #if debug
    var tempOffsets:Array<Int>;
    var inCharMenuDebug:Bool = false;
    var offsets:FlxText;
    var testOffsets:Array<Int> = [0, 0];
    var curChar:FlxText;
    var saveButton:FlxButton;
    var bgColorText:FlxText;
    var backgroundColor:Array<Int> = [0, 0, 0];
    var bgColorR:FlxUINumericStepper;
    var bgColorG:FlxUINumericStepper;
    var bgColorB:FlxUINumericStepper;
    var testColors:FlxButton;
    #end

    var charData:CharInfoData = {
        name: '',
        description: '',
        offsets: [0, 0],
        color: [0, 0, 0]
    };

    // The new function is only here to edit the choices in the menu
    public function new(charactersToChooseFrom:Array<String>){
        usedCharMenu = false;
        if (charactersToChooseFrom == null) charactersToChooseFrom = ['bf', 'gf', 'enemy'];
        super();
        for (i in 0...charactersToChooseFrom.length) {
            if (charactersToChooseFrom[i].toLowerCase().startsWith('player') || charactersToChooseFrom[i].toLowerCase().startsWith('boy') || charactersToChooseFrom[i].toLowerCase().startsWith('boyfriend') || charactersToChooseFrom[i].toLowerCase().startsWith('bf')) {
                charactersToChooseFrom[i] = 'bf';
            } else if (charactersToChooseFrom[i].toLowerCase().startsWith('girlfriend') || charactersToChooseFrom[i].toLowerCase().startsWith('girl') || charactersToChooseFrom[i].toLowerCase().startsWith('gf')) {
                charactersToChooseFrom[i] = 'gf';
            } else if (charactersToChooseFrom[i].toLowerCase().startsWith('enemy') || charactersToChooseFrom[i].toLowerCase().startsWith('dad') || charactersToChooseFrom[i].toLowerCase().startsWith('opponent')) {
                charactersToChooseFrom[i] = 'enemy';
            } else {charactersToChooseFrom.slice(i, 1);}
        }
        this.charactersToChooseFrom = charactersToChooseFrom;
    }

    function charsToChoose():Int {
        if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // All Characters
            return 1;
        } else if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // No Enemy
            return 2;
        } else if (!charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // No BF
            return 3;
        } else if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // No GF
            return 4;
        } else if (charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // Only BF
            return 5;
        } else if (!charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // Only GF
            return 6;
        } else if (!charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // Only Enemy
            return 7;
        } else return 0;
    }

    override function create() {
        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Choosing a Character", null);
		#end

        selectedColumn = charactersToChooseFrom[0];
        
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

        charMenuData();
        resetCharSelectVars();

        #if ACHIEVEMENTS_ALLOWED
        for (unlock in charsToUnlock) {
            if (characterLocks[charIndex.indexOf(unlock[0])][1] == "true") {continue;} 
            else if (Achievements.isUnlocked(unlock[1]) && unlock[1] != null) {characterLocks[charIndex.indexOf(unlock[0])][1] = "true";} 
            else {characterLocks[charIndex.indexOf(unlock[0])][1] = "false";}
        }

        FlxG.save.data.charactersAvailable = characterLocks;
        FlxG.save.flush();
        #end
        
        if (charactersToChooseFrom.length == 3) {
            leftThirdBG = initBGImage(leftThirdBG, "charMenu/leftThirdBG");
            middleThirdBG = initBGImage(middleThirdBG, "charMenu/middleThirdBG");
            rightThirdBG = initBGImage(rightThirdBG, "charMenu/rightThirdBG");
            add(leftThirdBG);
            add(rightThirdBG);
            add(middleThirdBG);
        } else if (charactersToChooseFrom.length == 2) {
            leftHalfBG = initBGImage(leftHalfBG, "charMenu/leftHalfBG");
            rightHalfBG = initBGImage(rightHalfBG, "charMenu/rightHalfBG");
            add(leftHalfBG);
            add(rightHalfBG);
        } else if (charactersToChooseFrom.length == 1) {
            fullBG = initBGImage(fullBG, "charMenu/fullBG");
            add(fullBG);
        }

        // Black bars over all backgrounds
        bgOverlay = initBGImage(bgOverlay, "charMenu/bgOverlay");
        add(bgOverlay);

        // Selector Shit
        selector = new FlxText(0, FlxG.height - 590, 0, "↓", 48);
        selector.setFormat(Paths.font('actual/vcr.ttf'), 48, FlxColor.BLACK, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);
        selector.borderSize = 2;

        // Self explanitory isn't it
        addCharsToScreen();
        changeSelection('enemy', 0, true);
        changeSelection('gf', 0, true);
        changeSelection('bf', 0, true);
        changeSelection('column', 0, true); // For the selector to fix - Torch

        // Put after the selections to not cause issues
        add(selector); 

        // All isn't needed as I can do that above
        if (charsToChoose() == 1) { // All Characters
            leftThirdBG.color = grabColor(enemyImageArray[selectedEnemy]);
            middleThirdBG.color = grabColor(gfImageArray[selectedGF]);
            rightThirdBG.color = grabColor(bfImageArray[selectedBF]);
        } else if (charsToChoose() == 2) { // No Enemy
            leftHalfBG.color = grabColor(gfImageArray[selectedGF]);
            rightHalfBG.color = grabColor(bfImageArray[selectedBF]);
        } else if (charsToChoose() == 3) { // No BF
            leftHalfBG.color = grabColor(enemyImageArray[selectedEnemy]);
            rightHalfBG.color = grabColor(gfImageArray[selectedGF]);
        } else if (charsToChoose() == 4) { // No GF
            leftHalfBG.color = grabColor(enemyImageArray[selectedEnemy]);
            rightHalfBG.color = grabColor(bfImageArray[selectedBF]);
        } else if (charsToChoose() == 5) { // Only BF
            fullBG.color = grabColor(bfImageArray[selectedBF]);
        } else if (charsToChoose() == 6) { // Only GF
            fullBG.color = grabColor(gfImageArray[selectedGF]);
        } else if (charsToChoose() == 7) { // Only Enemy
            fullBG.color = grabColor(enemyImageArray[selectedEnemy]);
        }

        #if debug
        offsets = new FlxText(FlxG.width * 0.7, FlxG.height * 0.8, 0, "", 32);
        offsets.setFormat('assets/fonts/vcr.ttf', 32, FlxColor.WHITE, RIGHT);
        add(offsets);

        curChar = new FlxText(FlxG.width * 0.1, FlxG.height * 0.9, 0, "", 32);
        curChar.setFormat('assets/fonts/vcr.ttf', 32, FlxColor.WHITE, RIGHT);
        add(curChar);

        saveButton = new FlxButton(FlxG.width * 0.7, FlxG.height * 0.95, "Save Info", function() {
            saveCharInfo();
        });
        add(saveButton);

        backgroundColor = charData.color;

        bgColorR = new FlxUINumericStepper(saveButton.x, saveButton.y - 40, 20, backgroundColor[0], 0, 255, 0);
        bgColorG = new FlxUINumericStepper(bgColorR.x + 65, bgColorR.y, 20, backgroundColor[1], 0, 255, 0);
        bgColorB = new FlxUINumericStepper(bgColorG.x + 65, bgColorG.y, 20, backgroundColor[2], 0, 255, 0);
        add(bgColorR);
        add(bgColorG);
        add(bgColorB);
        bgColorText = new FlxText(bgColorR.x, bgColorR.y - 18, 0, "Background R/G/B:");
        add(bgColorText);

        testColors = new FlxButton(saveButton.x, saveButton.y - 20, "Test BG Colors", function() {
            backgroundColor = [Math.round(bgColorR.value), Math.round(bgColorG.value), Math.round(bgColorB.value)];
            switch (selectedColumn) {
                case 'enemy':
                    if (charsToChoose() == 1) {
                        leftThirdBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == (3 | 4)) {
                        leftHalfBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == 7) {
                        fullBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else trace('This shit aint possible');
                case 'gf':
                    if (charsToChoose() == 1) {
                        middleThirdBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == 2) {
                        leftHalfBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == 3) {
                        rightHalfBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == 6) {
                        fullBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else trace('This shit aint possible');
                case 'bf':
                    if (charsToChoose() == 1) {
                        rightThirdBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == (2 | 4)) {
                        rightHalfBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else if (charsToChoose() == 5) {
                        fullBG.color = FlxColor.fromRGB(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
                    } else trace('This shit aint possible');
                default: 
                    trace('bruh, how there no column');
            }
        });
        add(testColors);
        #end

        // Character select text at the top of the screen
        var selectionHeader:Alphabet = new Alphabet(0, 50, 'Character Select', true);
        selectionHeader.screenCenter(X);
        add(selectionHeader);

        //cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]]; // Use normally for other engines, or prior to Psych 0.7.3
        camera = initPsychCamera(); // Apparently this fixed the Black Screen issue in Psych 0.7.3 - Torch
        super.create();

		FlxG.sound.playMusic(Paths.music('stayFunky', daFolder));
    }

    function initBGImage(bg:FlxSprite, path:String) {
        bg = new FlxSprite().loadGraphic(Paths.image(path, daFolder));
        bg.setGraphicSize(Std.int(bg.width * 1.1));
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = true;
        return bg;
    }

    function charPositioner(imageArray:Array<Character>, selectedCharVal:Int, ?numOfChars:Int = 1, ?leftMidRight:Int = 1) { // For use with initializeChars ONLY
        switch (numOfChars) {
            case 3:
                for (i in 0...imageArray.length) {
                    var tempOffsets:Array<Int> = grabOffsets(imageArray[i]);
                    imageArray[i].alpha = 0.8 - Math.abs(0.15 * (i - selectedCharVal));
                    if (StringTools.endsWith(imageArray[i].curCharacter, '-pixel') || imageArray[i].curCharacter.toLowerCase() == 'spirit' || StringTools.startsWith(imageArray[i].curCharacter, 'senpai')) { // This is preparing for problems
                        imageArray[i].y = (FlxG.height / 2) + ((i - selectedCharVal - 1) * charYOffset) + 475 + tempOffsets[1];
                    } else {
                        imageArray[i].y = (FlxG.height / 2) + ((i - selectedCharVal - 1) * charYOffset) + 200 + tempOffsets[1];
                    }
                    switch (leftMidRight) { // 1 - Left, 2 - Mid, 3 - Right
                        case 3:
                            imageArray[i].x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3, 2), FlxG.width) - (imageArray[i].width / 2) + tempOffsets[0];
                        case 2: 
                            imageArray[i].x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3), MathTools.fractionAmount(FlxG.width, 3, 2)) - (imageArray[i].width / 2) + tempOffsets[0];
                        case 1:
                            imageArray[i].x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 3)) - (imageArray[i].width / 2) + tempOffsets[0];
                    }
                }
            case 2:
                for (i in 0...imageArray.length) {
                    var tempOffsets:Array<Int> = grabOffsets(imageArray[i]);
                    imageArray[i].alpha = 0.8 - Math.abs(0.15 * (i - selectedCharVal));
                    if (StringTools.endsWith(imageArray[i].curCharacter, '-pixel') || imageArray[i].curCharacter.toLowerCase() == 'spirit' || StringTools.startsWith(imageArray[i].curCharacter, 'senpai')) { // This is preparing for problems
                        imageArray[i].y = (FlxG.height / 2) + ((i - selectedCharVal - 1) * charYOffset) + 475  + tempOffsets[1];
                    } else {
                        imageArray[i].y = (FlxG.height / 2) + ((i - selectedCharVal - 1) * charYOffset) + 200 + tempOffsets[1];
                    }
                    switch (leftMidRight) { // 1 - Left, 2 - Right
                        case 2: 
                            imageArray[i].x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (imageArray[i].width / 2) + tempOffsets[0];
                        case 1:
                            imageArray[i].x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (imageArray[i].width / 2) + tempOffsets[0];
                    }
                }
            case 1:
                for (i in 0...imageArray.length) {
                    var tempOffsets:Array<Int> = grabOffsets(imageArray[i]);
                    imageArray[i].alpha = 0.8 - Math.abs(0.15 * (i - selectedCharVal));
                    if (StringTools.endsWith(imageArray[i].curCharacter, '-pixel') || imageArray[i].curCharacter.toLowerCase() == 'spirit' || StringTools.startsWith(imageArray[i].curCharacter, 'senpai')) { // This is preparing for problems
                        imageArray[i].y = (FlxG.height / 2) + ((i - selectedCharVal - 1) * charYOffset) + 475 + tempOffsets[1];
                    } else {
                        imageArray[i].y = (FlxG.height / 2) + ((i - selectedCharVal - 1) * charYOffset) + 200 + tempOffsets[1];
                    }
                    imageArray[i].x = (FlxG.width / 2) - (imageArray[i].width / 2) + tempOffsets[0];
                } //XD
        }
    }

    function initializeChars() { 
        if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // All Three
            charPositioner(enemyImageArray, selectedEnemy, 3, 1);
            charPositioner(gfImageArray, selectedGF, 3, 2);
            charPositioner(bfImageArray, selectedBF, 3, 3);
        } else if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // No Enemy
            charPositioner(gfImageArray, selectedGF, 2, 1);
            charPositioner(bfImageArray, selectedBF, 2, 2);
        } else if (charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // No GF
            charPositioner(enemyImageArray, selectedEnemy, 2, 1);
            charPositioner(bfImageArray, selectedBF, 2, 2);
        } else if (!charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // No BF
            charPositioner(enemyImageArray, selectedEnemy, 2, 1);
            charPositioner(gfImageArray, selectedGF, 2, 2);
        } else if (charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // Only BF
            charPositioner(bfImageArray, selectedBF);
        } else if (!charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // Only Enemy
            charPositioner(enemyImageArray, selectedEnemy);
        } else if (!charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // Only GF
            charPositioner(gfImageArray, selectedGF);
        }

        if (charactersToChooseFrom.contains('enemy')) {enemyImageArray[selectedEnemy].alpha = 1;}
        if (charactersToChooseFrom.contains('gf')) {gfImageArray[selectedGF].alpha = 1;}
        if (charactersToChooseFrom.contains('bf')) {bfImageArray[selectedBF].alpha = 1;}

        charCheck();
    }

    function setColorTweens(numTweens:Int, imageArrayArray:Array<Array<Character>>, selectedChars:Array<Int>) { // For Use only with CharCheck
        switch (numTweens) {
            case 3:
                colorTweens[0] = FlxTween.color(leftThirdBG, tweenTime, leftThirdBG.color, grabColor(imageArrayArray[0][selectedChars[0]]), {ease: FlxEase.sineOut});
                colorTweens[1] = FlxTween.color(middleThirdBG, tweenTime, middleThirdBG.color, grabColor(imageArrayArray[1][selectedChars[1]]), {ease: FlxEase.sineOut});
                colorTweens[2] = FlxTween.color(rightThirdBG, tweenTime, rightThirdBG.color, grabColor(imageArrayArray[2][selectedChars[2]]), {ease: FlxEase.sineOut});
            case 2:
                colorTweens[0] = FlxTween.color(leftHalfBG, tweenTime, leftHalfBG.color, grabColor(imageArrayArray[0][selectedChars[0]]), {ease: FlxEase.sineOut});
                colorTweens[1] = FlxTween.color(rightHalfBG, tweenTime, rightHalfBG.color, grabColor(imageArrayArray[1][selectedChars[1]]), {ease: FlxEase.sineOut});
            case 1:
                colorTweens[0] = FlxTween.color(fullBG, tweenTime, fullBG.color, grabColor(imageArrayArray[0][selectedChars[0]]), {ease: FlxEase.sineOut});
        }
    }

    function charCheck() {
        if (colorTweens[0] != null) colorTweens[0].cancel();
        if (colorTweens[1] != null) colorTweens[1].cancel();
        if (colorTweens[2] != null) colorTweens[2].cancel();

        if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // All Chars
            setColorTweens(3, [enemyImageArray, gfImageArray, bfImageArray], [selectedEnemy, selectedGF, selectedBF]);
        } else if (charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // No Enemy
            setColorTweens(2, [gfImageArray, bfImageArray], [selectedGF, selectedBF]);
        } else if (charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // No GF
            setColorTweens(2, [enemyImageArray, bfImageArray], [selectedEnemy, selectedBF]);
        } else if (charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // No BF
            setColorTweens(2, [enemyImageArray, gfImageArray], [selectedEnemy, selectedGF]);
        } else if (charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // Only BF
            setColorTweens(1, [bfImageArray], [selectedBF]);
        } else if (!charactersToChooseFrom.contains('bf') && charactersToChooseFrom.contains('gf') && !charactersToChooseFrom.contains('enemy')) { // Only GF
            setColorTweens(1, [gfImageArray], [selectedGF]);
        } else if (!charactersToChooseFrom.contains('bf') && !charactersToChooseFrom.contains('gf') && charactersToChooseFrom.contains('enemy')) { // Only Enemy
            setColorTweens(1, [enemyImageArray], [selectedEnemy]);
        }

        if (charactersToChooseFrom.contains('enemy')) {
            remove(enemyIcon);
            enemyIcon = new HealthIcon(enemyImageArray[selectedEnemy].healthIcon, false);
            enemyIcon.setGraphicSize(-4);
            switch (charactersToChooseFrom.length) {
                case 3: 
                    enemyIcon.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 3)) - (enemyIcon.width / 2);
                case 2:
                    enemyIcon.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (enemyIcon.width / 2);
                case 1:
                    enemyIcon.x = (FlxG.width / 2) - (enemyIcon.width / 2);
            }
            enemyIcon.y = ((FlxG.height * 0.9) + 4) - (enemyIcon.height / 2) - 20;
            add(enemyIcon);
        }
        if (charactersToChooseFrom.contains('gf')) {
            remove(gfIcon);
            gfIcon = new HealthIcon(gfImageArray[selectedGF].healthIcon, false);
            gfIcon.setGraphicSize(-4);
            switch (charactersToChooseFrom.length) {
                case 3: 
                    gfIcon.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3), MathTools.fractionAmount(FlxG.width, 3, 2)) - (gfIcon.width / 2);
                case 2:
                    if (!charactersToChooseFrom.contains('enemy')) {
                        gfIcon.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (gfIcon.width / 2);
                    } else if (!charactersToChooseFrom.contains('bf')) {
                        gfIcon.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (gfIcon.width / 2);
                    }
                case 1:
                    gfIcon.x = (FlxG.width / 2) - (gfIcon.width / 2);
            }
            gfIcon.y = ((FlxG.height * 0.9) + 4) - (gfIcon.height / 2) - 20;
            add(gfIcon);
        }
        if (charactersToChooseFrom.contains('bf')) {
            remove(bfIcon);
            bfIcon = new HealthIcon(bfImageArray[selectedBF].healthIcon, true);
            bfIcon.setGraphicSize(-4);
            switch (charactersToChooseFrom.length) {
                case 3: 
                    bfIcon.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3, 2), FlxG.width) - (bfIcon.width / 2);
                case 2:
                    bfIcon.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (bfIcon.width / 2);
                case 1:
                    bfIcon.x = (FlxG.width / 2) - (bfIcon.width / 2);
            }
            bfIcon.y = ((FlxG.height * 0.9) + 4) - (bfIcon.height / 2) - 20;
            add(bfIcon);
        }
    }

    function addCharsToScreen() { //Should only be used in the create function
        checkBaseSongsForGf();
        var blockedSongs:Array<String> = [];
        var blockedChars:Array<Array<String>> = [];
        for (blacklist in 0...blockedCharactersPerSong.length) {
            blockedSongs.push(blockedCharactersPerSong[blacklist][0]);
            blockedChars.push(blockedCharactersPerSong[blacklist][1]);
        }

        for (song in 0...blockedSongs.length) { // THIS SHIT IS FUCKING DUMB BUT IT WORKS SO FUCK IT - Torch
            if (blockedSongs[song] == PlayState.SONG.song.toLowerCase()) {
                for (char in blockedChars[song]) {
                    if (pixelSong) {
                        for (list in pixelCharacters) {
                            for (i in 0...list.length) {
                                if ( i==0 ) continue;
                                else {if (list[i] == char) list.splice(i, 1);}
                            }
                        }
                    } else {
                        for (list in standardCharacters) {
                            for (i in 0...list.length) {
                                if (i == 0) {continue;}
                                else {if (list[i] == char) list.splice(i, 1);}
                            }
                        }
                    }
                }
            }
        }
        checkIfCharAlreadyExists();

        if (charactersToChooseFrom.contains('gf')) {
            var charArray:Array<String> = pixelSong ? pixelCharacters[1] : standardCharacters[1];
            var removeChars:Array<String> = [];
            for (i in 0...charArray.length)
            {
                var locked:Bool = false; 
                if (charArray[i] != charArray[0]) {
                    if (characterLocks[ArrayTools.grabFirstVal(characterLocks).indexOf(charArray[i])][1].toLowerCase() == "false") {
                        locked = true;
                    }
                }
                if (ClientPrefs.data.loadLockedChars == false && locked) {
                    removeChars.push(charArray[i]);
                    continue;
                }
                var characterImage:Character = new Character(0, 0, charArray[i]);
                characterImage.scale.set(charScale * characterImage.scale.x, charScale * characterImage.scale.y);
    
                if (locked) {characterImage.color = lockedColor;}
    
                characterImage.screenCenter(XY);
                switch (charactersToChooseFrom.length){
                    case 3: 
                        characterImage.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3), MathTools.fractionAmount(FlxG.width, 3, 2)) - (characterImage.width / 2);
                    case 2:
                        if (!charactersToChooseFrom.contains('enemy')) {
                            characterImage.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (characterImage.width / 2);
                        } else if (!charactersToChooseFrom.contains('bf')) {
                            characterImage.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (characterImage.width / 2);
                        }
                    case 1:
                        characterImage.x = (FlxG.width / 2) - (characterImage.width / 2);
                }

                if (characterImage.curCharacter == 'pico-speaker') {characterImage.playAnim('shoot1-loop', true);}

                gfImageArray.push(characterImage);
                add(characterImage);
            }
            for (name in removeChars) {
                charArray.remove(name);
            }
            pixelSong ? pixelCharacters[1] : standardCharacters[1] = charArray;
        }
        if (charactersToChooseFrom.contains('bf')) {
            var charArray:Array<String> = pixelSong ? pixelCharacters[0] : standardCharacters[0];
            var removeChars:Array<String> = [];
            for (i in 0...charArray.length)
            {
                var locked:Bool = false;
                if (charArray[i] != charArray[0]) {
                    if (characterLocks[ArrayTools.grabFirstVal(characterLocks).indexOf(charArray[i])][1].toLowerCase() == "false") {
                        locked = true;
                    }
                }
                if (ClientPrefs.data.loadLockedChars == false && locked) {
                    removeChars.push(charArray[i]);
                    continue;
                }
                var characterImage:Character = new Character(0, 0, charArray[i], true);
                characterImage.scale.set(charScale * characterImage.scale.x, charScale * characterImage.scale.y);

                if (locked) {characterImage.color = lockedColor;}
    
                characterImage.screenCenter(XY);
                switch (charactersToChooseFrom.length){
                    case 3: 
                        characterImage.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3, 2), FlxG.width) - (characterImage.width / 2);
                    case 2:
                        characterImage.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (characterImage.width / 2);
                    case 1:
                        characterImage.x = (FlxG.width / 2) - (characterImage.width / 2);
                }

                bfImageArray.push(characterImage);
                add(characterImage);
            }
            for (name in removeChars) {
                charArray.remove(name);
            }
            pixelSong ? pixelCharacters[0] : standardCharacters[0] = charArray;
        }
        if (charactersToChooseFrom.contains('enemy')) {
            var charArray:Array<String> = pixelSong ? pixelCharacters[2] : standardCharacters[2];
            var removeChars:Array<String> = [];
            for (i in 0...charArray.length)
            {
                var locked:Bool = false;
                if (charArray[i] != charArray[0]) {
                    if (characterLocks[ArrayTools.grabFirstVal(characterLocks).indexOf(charArray[i])][1].toLowerCase() == "false") {
                        locked = true;
                    }
                }
                if (ClientPrefs.data.loadLockedChars == false && locked) {
                    removeChars.push(charArray[i]);
                    continue;
                }
                var characterImage:Character = new Character(0, 0, charArray[i]);
                characterImage.scale.set(charScale * characterImage.scale.x, charScale * characterImage.scale.y);
    
                if (locked) {characterImage.color = lockedColor;}
    
                characterImage.screenCenter(XY);
                switch (charactersToChooseFrom.length){
                    case 3: 
                        characterImage.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 3)) - (characterImage.width / 2);
                    case 2:
                        characterImage.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (characterImage.width / 2);
                    case 1:
                        characterImage.x = (FlxG.width / 2) - (characterImage.width / 2);
                }

                enemyImageArray.push(characterImage);
                add(characterImage);
            }
            for (name in removeChars) {
                charArray.remove(name);
            }
            pixelSong ? pixelCharacters[2] : standardCharacters[2] = charArray;
        }
        initializeChars();
    }

    private var fuckinTimer:FlxTimer;

    function checkIfAbleToContinue():Bool {
        if (charactersToChooseFrom.contains('bf')) {
            if (bfImageArray[selectedBF].color == lockedColor) {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                return false;
            }
        }
        if (charactersToChooseFrom.contains('gf')) {
            if (gfImageArray[selectedGF].color == lockedColor) {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                return false;
            }
        }
        if (charactersToChooseFrom.contains('enemy')) {
            if (enemyImageArray[selectedEnemy].color == lockedColor) {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                return false;
            }
        }
        return true;
    }


    function getCharName(column:String) {
        switch (column) {
            case 'enemy':
                return standardCharacters[2][selectedEnemy];
            case 'gf':
                return standardCharacters[1][selectedGF];
            case 'bf':
                return standardCharacters[0][selectedBF];
            default:
                return standardCharacters[0][0];
        }
    }

    #if debug
    // This will be changed later - Torch
    function saveCharInfo() {
        var file:FileReference;
        var saveName = getCharName(selectedColumn);
        charData.name = saveName; // Will be removed when I get live updating
        charData.color = backgroundColor;
        var data:String = haxe.Json.stringify(charData, "\t");

        /*
        var json:Dynamic = {
            "name": 'BOYFRIEND.XML',
            "description": '',
            "offsets": [-18, 283],
            "color": 0xFF00ABC5
        }
        var test:String = haxe.Json.stringify(json, "\t");
        trace(test);
        */

        if (data.length > 0) {
            file = new FileReference();
            file.save(data, '$saveName.json');
        }
    }

    // Partially work, though it doesn't seem to fully work with FlxUINumericStepper
    function changeAlpha(array:Array<Dynamic>, alpha:Int = 1) {
        for (item in array) {
            item.alpha = alpha;
        }
    }
    function changeActive(array:Array<Dynamic>, active:Bool = true) {
        for (item in array) {
            item.active = active;
        }
    }
    #end

    var disableUIKeys:Bool = false;

    override function update(elapsed:Float) {
        // Must be changed depending on how an engine uses its own controls
        var leftPress = controls.UI_LEFT_P; // Psych
        var rightPress = controls.UI_RIGHT_P; // Psych
        var upPress = controls.UI_UP_P;
        var downPress = controls.UI_DOWN_P;
        var accepted = controls.ACCEPT; // Should be Universal
        var goBack = controls.BACK; // Should be Universal

        #if debug
        var debugMode = FlxG.keys.justPressed.E;
        var moveDown = FlxG.keys.pressed.K;
        var moveUp = FlxG.keys.pressed.I;
        var moveLeft = FlxG.keys.pressed.J;
        var moveRight = FlxG.keys.pressed.L;
        var speedUp = FlxG.keys.pressed.SHIFT;
        var refreshButton = FlxG.keys.justPressed.CAPSLOCK;
        #end
        
        charInput += KeyboardTools.keypressToString();

        for (code in cheatCodes) {
            if (code.toUpperCase().trim().startsWith(charInput)) {
                if (charInput == code.toUpperCase().trim() && !invalidCodes.contains(code)) {
                    unlockChar(code);
                    charInput = '';
                } continue;
            } else {
                if (invalidCodes.contains(code)) continue;
                invalidCodes.push(code);
            }
            if (invalidCodes.length == cheatCodes.length) {
				invalidCodes = [];
				charInput = '';
			}
        }

        if (!alreadySelected) {
            //if (FlxG.keys.pressed.V) {testSave();}
            if (!disableUIKeys) {
                if (leftPress) {changeSelection(setColumn(-1));}
                if (rightPress) {changeSelection(setColumn(1));}
                if (upPress) {changeSelection(selectedColumn, -1);}
                if (downPress) {changeSelection(selectedColumn, 1);}
                if (accepted) {
                    if (checkIfAbleToContinue()) {
                        alreadySelected = true;
                        usedCharMenu = true;
                        FlxG.save.data.charactersAvailable = characterLocks;
                        FlxG.save.flush();
    
                        // This is just to ensure that the PlayState loads from the correct library.
                        var quickVar = Paths.formatToSongPath(PlayState.SONG.song.toLowerCase());
                        var songJson = Highscore.formatSong(quickVar, PlayState.storyDifficulty);
                        PlayState.SONG = Song.loadFromJson(songJson, quickVar);
                        PlayState.isStoryMode = !fromFreeplay;
                        PlayState.storyDifficulty = playstateDiff;
    
                        var theSelected:Array<String> = [
                            (pixelSong ? pixelCharacters[2] : standardCharacters[2])[selectedEnemy], 
                            (pixelSong ? pixelCharacters[1] : standardCharacters[1])[selectedGF], 
                            (pixelSong ? pixelCharacters[0] : standardCharacters[0])[selectedBF]
                        ];
                        if (theSelected[1] != PlayState.SONG.gfVersion)
                            PlayState.SONG.gfVersion = theSelected[1];
                        if ((PlayState.SONG.player2.startsWith('gf') || PlayState.SONG.player2 == PlayState.SONG.gfVersion) && theSelected[1] != PlayState.SONG.player2)
                            PlayState.SONG.player2 = theSelected[1];
                        else if (theSelected[0] != PlayState.SONG.player2)
                            PlayState.SONG.player2 = theSelected[0];
                        if (theSelected[2] != PlayState.SONG.player1)
                            PlayState.SONG.player1 = theSelected[2];
        
                        if (charactersToChooseFrom.contains('enemy')) {FlxFlicker.flicker(enemyImageArray[selectedEnemy], 0);}
                        if (charactersToChooseFrom.contains('gf')) {FlxFlicker.flicker(gfImageArray[selectedGF], 0);}
                        if (charactersToChooseFrom.contains('bf')) {FlxFlicker.flicker(bfImageArray[selectedBF], 0);}
        
                        FlxG.sound.music.volume = 0;
                        FreeplayState.destroyFreeplayVocals();
                        
                        new FlxTimer().start(0.75, function(tmr:FlxTimer) {LoadingState.loadAndSwitchState(new PlayState());});
                    }
                }
                if (goBack) {
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    if (PlayState.isStoryMode) LoadingState.loadAndSwitchState(new StoryMenuState());
                    else LoadingState.loadAndSwitchState(new FreeplayState());
                }
            }
            #if debug
            if (debugMode) {
                inCharMenuDebug = !inCharMenuDebug;
                if (charsToChoose() == (5 | 6 | 7)) {
                    bgColorR.value = leftHalfBG.color.red;
                    bgColorG.value = leftHalfBG.color.green;
                    bgColorB.value = leftHalfBG.color.blue;
                } else {
                    switch (selectedColumn) {
                        case 'enemy':
                            if (charsToChoose() == 1) {
                                bgColorR.value = leftThirdBG.color.red;
                                bgColorG.value = leftThirdBG.color.green;
                                bgColorB.value = leftThirdBG.color.blue;
                            } else if (charsToChoose() == (3 | 4)) {
                                bgColorR.value = leftHalfBG.color.red;
                                bgColorG.value = leftHalfBG.color.green;
                                bgColorB.value = leftHalfBG.color.blue;
                            } else trace('This shit aint possible');
                        case 'gf':
                            if (charsToChoose() == 1) {
                                bgColorR.value = middleThirdBG.color.red;
                                bgColorG.value = middleThirdBG.color.green;
                                bgColorB.value = middleThirdBG.color.blue;
                            } else if (charsToChoose() == 2) {
                                bgColorR.value = leftHalfBG.color.red;
                                bgColorG.value = leftHalfBG.color.green;
                                bgColorB.value = leftHalfBG.color.blue;
                            } else if (charsToChoose() == 3) {
                                bgColorR.value = rightHalfBG.color.red;
                                bgColorG.value = rightHalfBG.color.green;
                                bgColorB.value = rightHalfBG.color.blue;
                            } else trace('This shit aint possible');
                        case 'bf':
                            if (charsToChoose() == 1) {
                                bgColorR.value = rightThirdBG.color.red;
                                bgColorG.value = rightThirdBG.color.green;
                                bgColorB.value = rightThirdBG.color.blue;
                            } else if (charsToChoose() == (2 | 4)) {
                                bgColorR.value = rightHalfBG.color.red;
                                bgColorG.value = rightHalfBG.color.green;
                                bgColorB.value = rightHalfBG.color.blue;
                            } else trace('This shit aint possible');
                        default: 
                            trace('bruh, how there no column');
                    }
                }
            }
            if (refreshButton) {refreshState(true);} // Use only to fix broken save data
            if (inCharMenuDebug) {
                // I can't get it to hide all items sadly, so buttons and random black boxes from text fields stay - Torch
                changeActive([bgColorR, bgColorG, bgColorB, saveButton, testColors], true);
                changeAlpha([offsets, curChar, bgColorText, bgColorR, bgColorG, bgColorB, saveButton, saveButton.label, testColors, testColors.label], 1);
                //FlxG.mouse.visible = true;
                Cursor.show();
                disableUIKeys = true;

                @:privateAccess
                {
                    if ((bgColorR.text_field is FlxInputText)) {
                        var fit:FlxInputText = cast bgColorR.text_field;
                        fit.backgroundColor = FlxColor.WHITE;
                        fit.alpha = 1;
                    } else {
                        bgColorR.text_field.alpha = 1;
                    }
                    if ((bgColorG.text_field is FlxInputText)) {
                        var fit:FlxInputText = cast bgColorG.text_field;
                        fit.backgroundColor = FlxColor.WHITE;
                        fit.alpha = 1;
                    } else {
                        bgColorG.text_field.alpha = 1;
                    }
                    if ((bgColorB.text_field is FlxInputText)) {
                        var fit:FlxInputText = cast bgColorB.text_field;
                        fit.backgroundColor = FlxColor.WHITE;
                        fit.alpha = 1;
                    } else {
                        bgColorB.text_field.alpha = 1;
                    }
                }

                backgroundColor = [Math.round(bgColorR.value), Math.round(bgColorG.value), Math.round(bgColorB.value)];

                switch (selectedColumn) {
                    case 'enemy':
                        tempOffsets = grabOffsets(enemyImageArray[selectedEnemy]);
                        if(moveUp) {
                            if (speedUp) {
                                testOffsets[1] -= 10;
                                enemyImageArray[selectedEnemy].y -= 10;
                            } else {
                                testOffsets[1]--; 
                                enemyImageArray[selectedEnemy].y--;
                            }
                        }
                        if(moveDown) {
                            if (speedUp) {
                                testOffsets[1] += 10; 
                                enemyImageArray[selectedEnemy].y += 10;
                            } else {
                                testOffsets[1]++; 
                                enemyImageArray[selectedEnemy].y++;
                            }
                        }
                        if(moveLeft) {
                            if (speedUp) {
                                testOffsets[0] -= 10; 
                                enemyImageArray[selectedEnemy].x -= 10;
                            } else {
                                testOffsets[0]--; 
                                enemyImageArray[selectedEnemy].x--;
                            }
                        }
                        if(moveRight) {
                            if (speedUp) {
                                testOffsets[0] += 10; 
                                enemyImageArray[selectedEnemy].x += 10;
                            } else {
                                testOffsets[0]++; 
                                enemyImageArray[selectedEnemy].x++;
                            }
                        }
                        curChar.text = enemyImageArray[selectedEnemy].curCharacter;
                    case 'gf':
                        tempOffsets = grabOffsets(gfImageArray[selectedGF]);
                        if(moveUp) {
                            if (speedUp) {
                                testOffsets[1] -= 10;
                                gfImageArray[selectedGF].y -= 10;
                            } else {
                                testOffsets[1]--; 
                                gfImageArray[selectedGF].y--;
                            }
                        }
                        if(moveDown) {
                            if (speedUp) {
                                testOffsets[1] += 10; 
                                gfImageArray[selectedGF].y += 10;
                            } else {
                                testOffsets[1]++; 
                                gfImageArray[selectedGF].y++;
                            }
                        }
                        if(moveLeft) {
                            if (speedUp) {
                                testOffsets[0] -= 10; 
                                gfImageArray[selectedGF].x -= 10;
                            } else {
                                testOffsets[0]--; 
                                gfImageArray[selectedGF].x--;
                            }
                        }
                        if(moveRight) {
                            if (speedUp) {
                                testOffsets[0] += 10; 
                                gfImageArray[selectedGF].x += 10;
                            } else {
                                testOffsets[0]++; 
                                gfImageArray[selectedGF].x++;
                            }
                        }
                        curChar.text = gfImageArray[selectedGF].curCharacter;
                    case 'bf':
                        tempOffsets = grabOffsets(bfImageArray[selectedBF]);
                        if(moveUp) {
                            if (speedUp) {
                                testOffsets[1] -= 10;
                                bfImageArray[selectedBF].y -= 10;
                            } else {
                                testOffsets[1]--; 
                                bfImageArray[selectedBF].y--;
                            }
                        }
                        if(moveDown) {
                            if (speedUp) {
                                testOffsets[1] += 10; 
                                bfImageArray[selectedBF].y += 10;
                            } else {
                                testOffsets[1]++; 
                                bfImageArray[selectedBF].y++;
                            }
                        }
                        if(moveLeft) {
                            if (speedUp) {
                                testOffsets[0] -= 10; 
                                bfImageArray[selectedBF].x -= 10;
                            } else {
                                testOffsets[0]--; 
                                bfImageArray[selectedBF].x--;
                            }
                        }
                        if(moveRight) {
                            if (speedUp) {
                                testOffsets[0] += 10; 
                                bfImageArray[selectedBF].x += 10;
                            } else {
                                testOffsets[0]++; 
                                bfImageArray[selectedBF].x++;
                            }
                        }
                        curChar.text = bfImageArray[selectedBF].curCharacter;
                }
                offsets.text = "Current Character's\nMenu Offsets:\nX: " + (tempOffsets[0] + testOffsets[0]) + "\nY: " + (tempOffsets[1] + testOffsets[1]);

                charData.offsets = [tempOffsets[0] + testOffsets[0], tempOffsets[1] + testOffsets[1]];
            } else {
                changeActive([bgColorR, bgColorG, bgColorB, saveButton, testColors], false);
                changeAlpha([offsets, curChar, bgColorText, bgColorR, bgColorG, bgColorB, saveButton, saveButton.label, testColors, testColors.label], 0);
                //FlxG.mouse.visible = false;
                Cursor.hide();
                disableUIKeys = false;

                @:privateAccess 
                {
                    if ((bgColorR.text_field is FlxInputText)) {
                        var fit:FlxInputText = cast bgColorR.text_field;
                        fit.backgroundColor = FlxColor.TRANSPARENT;
                        fit.alpha = 0;
                    } else {
                        bgColorR.text_field.alpha = 0;
                    }
                    if ((bgColorG.text_field is FlxInputText)) {
                        var fit:FlxInputText = cast bgColorG.text_field;
                        fit.backgroundColor = FlxColor.TRANSPARENT;
                        fit.alpha = 0;
                    } else {
                        bgColorG.text_field.alpha = 0;
                    }
                    if ((bgColorB.text_field is FlxInputText)) {
                        var fit:FlxInputText = cast bgColorB.text_field;
                        fit.backgroundColor = FlxColor.TRANSPARENT;
                        fit.alpha = 0;
                    } else {
                        bgColorB.text_field.alpha = 0;
                    }
                }
            }
            #end
        }

        if (fuckinTimer == null) {
            if (charactersToChooseFrom.contains('gf')) {
                if (gfImageArray[selectedGF].curCharacter == 'pico-speaker') {
                    gfImageArray[selectedGF].playAnim('shoot1-loop', true);
                }
            }
            fuckinTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer) {
                if (charactersToChooseFrom.contains('enemy')) {enemyImageArray[selectedEnemy].dance();}
                if (charactersToChooseFrom.contains('gf')) {
                    if (gfImageArray[selectedGF].curCharacter == 'pico-speaker') {
                        gfImageArray[selectedGF].playAnim('shoot1-loop', true);
                    } else {gfImageArray[selectedGF].dance();}
                }
                if (charactersToChooseFrom.contains('bf')) { bfImageArray[selectedBF].dance();}
            }, 0);
        }

        super.update(elapsed);
    }

    public function unlockChar(whoToUnlock:String) {
        var valueChanged:Bool = false;
        switch (whoToUnlock.toLowerCase().trim()) {
            case 'ugh':
                if (characterLocks[charIndex.indexOf('tankman-player')][1] == "false") {
                    characterLocks[charIndex.indexOf('tankman-player')][1] = "true";
                    valueChanged = true;
                }
            case 'remove': // Only here for debug purposes, will be removed in the future
                if (characterLocks[charIndex.indexOf('torch')][1] == "true" || characterLocks[charIndex.indexOf('tankman-player')][1] == "true") {
                    characterLocks[charIndex.indexOf('tankman-player')][1] = "false";
                    characterLocks[charIndex.indexOf('torch')][1] = "false";
                    valueChanged = true;
                }
            case 'torch':
                if (characterLocks[charIndex.indexOf('torch')][1] == "false") {
                    characterLocks[charIndex.indexOf('torch')][1] = "true";
                    valueChanged = true;
                }
            default:
                trace("Sorry, but " + whoToUnlock + " is not a valid character.");
        }
        if (valueChanged) refreshState();
    }

    private var charInput:String = '';
    private var cheatCodes:Array<String> = ['ugh','torch','remove' /*leave remove as a failsafe*/];
    private var invalidCodes:Array<String> = [];

    // This function is used to refresh the state when something new happens, like unlocking a character
    function refreshState(forceUpdate:Bool = false) {
        FlxG.save.data.charactersAvailable = characterLocks;
        FlxG.save.flush();
        forceCharUnlockSaveUpdate(forceUpdate);
        LoadingState.loadAndSwitchState(new CharacterMenu(charactersToChooseFrom));
    }

    function changeSelection(whichOne:String, ?changeAmount:Int = 0, ?initial = false) {
        if (!initial) {FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);}
        switch (whichOne) {
            case 'enemy': // Enemy
                selectedEnemy += changeAmount;
                if (selectedEnemy < 0)
                    selectedEnemy = (pixelSong ? pixelCharacters[2] : standardCharacters[2]).length - 1;
                if (selectedEnemy >= (pixelSong ? pixelCharacters[2] : standardCharacters[2]).length)
                    selectedEnemy = 0;

                if (enemyImageArray.length != 1) {
                    for (i in 0...enemyImageArray.length) {
                        var tempOffsets:Array<Int> = grabOffsets(enemyImageArray[i]);
                        var desiredAlpha:Float = 0;
                        if (i == selectedEnemy) desiredAlpha = 1;
                        else desiredAlpha = 0.8 - Math.abs(0.15 * (i - selectedEnemy));

                        if (alphaTweens[0][i] != null) alphaTweens[0][i].cancel();
                        alphaTweens[0][i] = FlxTween.tween(enemyImageArray[i], {alpha : desiredAlpha}, tweenTime, {ease: FlxEase.sineOut});

                        var destY:Float = 0;

                        if (StringTools.endsWith(enemyImageArray[i].curCharacter, '-pixel') || enemyImageArray[i].curCharacter.toLowerCase() == 'spirit' || StringTools.startsWith(enemyImageArray[i].curCharacter, 'senpai')) {
                            destY = (FlxG.height / 2) + ((i - selectedEnemy - 1) * charYOffset) + 475 + tempOffsets[1];
                        } else {destY = (FlxG.height / 2) + ((i - selectedEnemy - 1) * charYOffset) + 200 + tempOffsets[1];}

                        if (enemyDestTweens[i] != null) enemyDestTweens[i].cancel();
                        enemyDestTweens[i] = FlxTween.tween(enemyImageArray[i], {y : destY}, tweenTime, {ease: FlxEase.quadInOut});
                    }
                }
            case 'gf': // GF
                selectedGF += changeAmount;
                if (selectedGF < 0)
                    selectedGF = (pixelSong ? pixelCharacters[1] : standardCharacters[1]).length - 1;
                if (selectedGF >= (pixelSong ? pixelCharacters[1] : standardCharacters[1]).length)
                    selectedGF = 0;
                
                if (gfImageArray.length != 1) {
                    for (i in 0...gfImageArray.length) {
                        var tempOffsets:Array<Int> = grabOffsets(gfImageArray[i]);
                        var desiredAlpha:Float = 0;
                        if (i == selectedGF) desiredAlpha = 1;
                        else desiredAlpha = 0.8 - Math.abs(0.15 * (i - selectedGF));

                        if (alphaTweens[1][i] != null) alphaTweens[1][i].cancel();
                        alphaTweens[1][i] = FlxTween.tween(gfImageArray[i], {alpha : desiredAlpha}, tweenTime, {ease: FlxEase.sineOut});

                        var destY:Float = 0;

                        if (StringTools.endsWith(gfImageArray[i].curCharacter, '-pixel') || gfImageArray[i].curCharacter.toLowerCase() == 'spirit' || StringTools.startsWith(gfImageArray[i].curCharacter, 'senpai')) {
                            destY = (FlxG.height / 2) + ((i - selectedGF - 1) * charYOffset) + 475 + tempOffsets[1];
                        } else {destY = (FlxG.height / 2) + ((i - selectedGF - 1) * charYOffset) + 200 + tempOffsets[1];}

                        if (gfDestTweens[i] != null) gfDestTweens[i].cancel();
                        gfDestTweens[i] = FlxTween.tween(gfImageArray[i], {y : destY}, tweenTime, {ease: FlxEase.quadInOut});
                    }
                }
            case 'bf': // BF
                selectedBF += changeAmount;
                if (selectedBF < 0)
                    selectedBF = (pixelSong ? pixelCharacters[0] : standardCharacters[0]).length - 1;
                if (selectedBF >= (pixelSong ? pixelCharacters[0] : standardCharacters[0]).length)
                    selectedBF = 0;
                
                if (bfImageArray.length != 1) {
                    for (i in 0...bfImageArray.length) {
                        var tempOffsets:Array<Int> = grabOffsets(bfImageArray[i]);
                        var desiredAlpha:Float = 0;
                        if (i == selectedBF) desiredAlpha = 1;
                        else desiredAlpha = 0.8 - Math.abs(0.15 * (i - selectedBF));

                        if (alphaTweens[2][i] != null) alphaTweens[2][i].cancel();
                        alphaTweens[2][i] = FlxTween.tween(bfImageArray[i], {alpha : desiredAlpha}, tweenTime, {ease: FlxEase.sineOut});

                        var destY:Float = 0;

                        if (StringTools.endsWith(bfImageArray[i].curCharacter, '-pixel') || bfImageArray[i].curCharacter.toLowerCase() == 'spirit' || StringTools.startsWith(bfImageArray[i].curCharacter, 'senpai')) {
                            destY = (FlxG.height / 2) + ((i - selectedBF - 1) * charYOffset) + 475 + tempOffsets[1];
                        } else {destY = (FlxG.height / 2) + ((i - selectedBF - 1) * charYOffset) + 200 + tempOffsets[1];}

                        if (bfDestTweens[i] != null) bfDestTweens[i].cancel();
                        bfDestTweens[i] = FlxTween.tween(bfImageArray[i], {y : destY}, tweenTime, {ease: FlxEase.quadInOut});
                    } 
                }
            case 'column': // Just for moving left to right
                if (selector.visible) {
                    switch (selectedColumn) {
                        case 'enemy': // Enemy
                            switch (charactersToChooseFrom.length) {
                                case 3: 
                                    selector.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 3)) - (selector.fieldWidth / 2);
                                case 2:
                                    selector.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (selector.fieldWidth / 2);
                                case 1:
                                    selector.x = (FlxG.width / 2) - (selector.fieldWidth / 2);
                            }
                        case 'gf': // GF
                            switch (charactersToChooseFrom.length) {
                                case 3: 
                                    selector.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3), MathTools.fractionAmount(FlxG.width, 3, 2)) - (selector.fieldWidth / 2);
                                case 2:
                                    if (!charactersToChooseFrom.contains('enemy')) {
                                        selector.x = MathTools.midpoint(0, MathTools.fractionAmount(FlxG.width, 2)) - (selector.fieldWidth / 2);
                                    } else if (!charactersToChooseFrom.contains('bf')) {
                                        selector.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (selector.fieldWidth / 2);
                                    }
                                case 1:
                                    selector.x = (FlxG.width / 2) - (selector.fieldWidth / 2);
                            }
                        case 'bf': // BF
                            switch (charactersToChooseFrom.length) {
                                case 3: 
                                    selector.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 3, 2), FlxG.width) - (selector.fieldWidth / 2);
                                case 2:
                                    selector.x = MathTools.midpoint(MathTools.fractionAmount(FlxG.width, 2), FlxG.width) - (selector.fieldWidth / 2);
                                case 1:
                                    selector.x = (FlxG.width / 2) - (selector.fieldWidth / 2);
                            }
                    }
                }
        }
        charCheck();
    }

    function setColumn(changeAmount:Int) {
        if (changeAmount == -1) {
            if (charactersToChooseFrom.contains('bf') && selectedColumn == 'bf') {
                if (charactersToChooseFrom.contains('gf')) {selectedColumn = 'gf';} 
                else if (charactersToChooseFrom.contains('enemy')) {selectedColumn = 'enemy';} 
                else {selectedColumn = 'bf';}
            } else if (charactersToChooseFrom.contains('gf') && selectedColumn == 'gf') {
                if (charactersToChooseFrom.contains('enemy')) {selectedColumn = 'enemy';} 
                else if (charactersToChooseFrom.contains('bf')) {selectedColumn = 'bf';} 
                else {selectedColumn = 'gf';}
            } else if (charactersToChooseFrom.contains('enemy') && selectedColumn == 'enemy') {
                if (charactersToChooseFrom.contains('bf')) {selectedColumn = 'bf';} 
                else if (charactersToChooseFrom.contains('gf')) {selectedColumn = 'gf';} 
                else {selectedColumn = 'enemy';}
            }
        } else if (changeAmount == 1) {
            if (charactersToChooseFrom.contains('bf') && selectedColumn == 'bf') {
                if (charactersToChooseFrom.contains('enemy')) {selectedColumn = 'enemy';} 
                else if (charactersToChooseFrom.contains('gf')) {selectedColumn = 'gf';}
                else {selectedColumn = 'bf';}
            } else if (charactersToChooseFrom.contains('gf') && selectedColumn == 'gf') {
                if (charactersToChooseFrom.contains('bf')) {selectedColumn = 'bf';} 
                else if (charactersToChooseFrom.contains('enemy')) {selectedColumn = 'enemy';} 
                else {selectedColumn = 'gf';}
            } else if (charactersToChooseFrom.contains('enemy') && selectedColumn == 'enemy') {
                if (charactersToChooseFrom.contains('gf')) {selectedColumn = 'gf';} 
                else if (charactersToChooseFrom.contains('bf')) {selectedColumn = 'bf';} 
                else {selectedColumn = 'enemy';}
            }
        }
        return 'column';
    }

    // Dont edit these two, they are a couple of util functions I use
    function grabColor(character:Character) {
        var color:String = '';
        for (i in 0...allColors.length) {if (character.curCharacter == allColors[i][0]) {color = allColors[i][1].trim(); break;} else {color = allColors[0][1].trim();}}
        return FlxColor.fromString(color);
    }
    function grabOffsets(character:Character):Array<Int> {
        for (i in 0...allOffsets.length) {if (character.curCharacter == allOffsets[i][0]) {return [Std.parseInt(allOffsets[i][1]), Std.parseInt(allOffsets[i][2])];}}
        return [Std.parseInt(allOffsets[0][1]), Std.parseInt(allOffsets[0][2])];
    }

    function checkIfCharAlreadyExists() {
        if (pixelSong) {
            for (list in pixelCharacters) {
                for (i in 0...list.length) {
                    if ( i==0 ) continue;
                    else {if (list[i] == list[0]) list.splice(i, 1);}
                }
            }
        } else {
            for (list in standardCharacters) {
                for (i in 0...list.length) {
                    if (i == 0) {continue;}
                    else {if (list[i] == list[0]) list.splice(i, 1);}
                }
            }
        }
    }

    function checkBaseSongsForGf() { // Edit this if you need to fix default songs for some reason
        var gfArray:Array<String> = pixelSong ? pixelCharacters[1] : standardCharacters[1];
        if (PlayState.SONG.gfVersion != null && PlayState.SONG.gfVersion != '') gfArray[0] = PlayState.SONG.gfVersion; 
        else {
            switch (PlayState.SONG.song.toLowerCase()) {
                case 'high' | 'milf' | 'satin-panties':
					gfArray[0] = 'gf-car';
				case 'eggnog' | 'cocoa':
					gfArray[0] = 'gf-christmas';
				case 'roses' | 'thorns' | 'senpai':
					gfArray[0] = 'gf-pixel';
				case 'guns' | 'ugh':
					gfArray[0] = 'gf-tankmen';
				default:
					gfArray[0] = 'gf';
            }
        }
        pixelSong ? pixelCharacters[1] : standardCharacters[1] = gfArray;
    }

    function getUnlockedChars() {
        var unlocked:Array<String> = [];
        FlxG.save.data.unlockedCharacters = defaultUnlocked;
        FlxG.save.flush();
        unlocked = FlxG.save.data.unlockedCharacters;
        return unlocked;
    }

    function forceCharUnlockSaveUpdate(forceAllUpdates:Bool = false) {
        if (characterList == null || characterList == [] || characterList.length < 1 || forceAllUpdates) characterList = allCharacters(); 
        var failsafeString:String = 'No Character Should Be Using This Name';
        var tempSaveArray:Array<Array<String>> = FlxG.save.data.charactersAvailable;
		if (tempSaveArray == null || tempSaveArray == [] || tempSaveArray.length < 1 || forceAllUpdates) {tempSaveArray = [[failsafeString, "false"]];}
        var unlockedChars:Array<String> = FlxG.save.data.unlockedCharacters;
        if (unlockedChars == null || unlockedChars == [] || unlockedChars.length < 1 || forceAllUpdates) {unlockedChars = getUnlockedChars();}

        clearAllSaveData();

        for (array in tempSaveArray) if (array[0].toString() == failsafeString) tempSaveArray.remove(array); 
		var tempArray = ArrayTools.grabFirstVal(tempSaveArray);

        for (char in characterList) {
            var truray:Array<String> = [char, "true"];
            var falray:Array<String> = [char, "false"];
            if (tempArray.indexOf(char) != -1) {if (tempSaveArray.contains(truray)) {continue;}
            } else if (unlockedChars != null && unlockedChars.contains(char) && !(tempSaveArray.contains(truray))) {
                tempArray.insert(characterList.indexOf(char), char);
                tempSaveArray.insert(characterList.indexOf(char), [char,"true"]);
            } else if (unlockedChars != null && !unlockedChars.contains(char) && !(tempSaveArray.contains(falray))) {
                tempArray.insert(characterList.indexOf(char), char);
                tempSaveArray.insert(characterList.indexOf(char), [char,"false"]);
            }
        }

        characterLocks = tempSaveArray;
        charIndex = tempArray;
		FlxG.save.data.charactersAvailable = tempSaveArray;
		FlxG.save.data.maxCharacters = characterList.length;
        FlxG.save.data.unlockedCharacters = unlockedChars;
        FlxG.save.flush();
	}

    // Just an FWI, this is a fix for allowing mods, though I do not recommended to use mod skins
	public function allCharacters() {
        var tempList = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
        for (name in unlistedCharacters) {if (!tempList.contains(name)) tempList.push(name);}

        // Used for the default mod folder, aka, the global mods
        if (FileSystem.exists(Paths.mods('characters/'))) {
            for (modChar in FileSystem.readDirectory(Paths.mods('characters/'))) {tempList.push(Std.string(modChar).replace(".json", ""));}
        }

        // Used for the mods added to the mods folder
        var modList = Mods.getModDirectories();
        for (mod in 0...modList.length) {
            var modName:String = modList[mod];
            var modPath:String = Paths.mods();
            if (modName != '' || modName != null) modPath = Paths.mods(modName + '/'); // Just a failsafe
            if (FileSystem.exists(modPath + 'characters/')) {
                for (modChar in FileSystem.readDirectory(modPath + 'characters/')) {tempList.push(Std.string(modChar).replace(".json", ""));}
            }
        }
		return tempList;
	}

    // Not implemented at all, have to figure out what to do with everything...
    public function loadCharData(char:String) {
        charData = haxe.Json.parse(Assets.getText(Paths.json('charData/' + char, daFolder)));
        if (charData == null) {
            charData = {
                name: 'Default',
                description: 'Default Description',
                offsets: [0, 0],
                color: [0, 0, 0]
            };
        }
        
        if (!allColors.contains([charData.name, charData.color.toString()])) {
            allColors.push([charData.name, charData.color.toString()]);
        }
    }

    // This will be changed once I get json files made
    public function charMenuData() { // HOLY SHIT I GOT ACTUAL MOD SUPPORT
        var tempColorArray = Assets.getText(Paths.txt('charMenu/characterColors', daFolder)).trim().split("\n");
        var tempNameArray = Assets.getText(Paths.txt('charMenu/characterNames', daFolder)).trim().split("\n");
        var tempOffsetArray = Assets.getText(Paths.txt('charMenu/characterOffsets', daFolder)).trim().split("\n");

        if (FileSystem.exists(Paths.mods('data/charMenu/'))) {
            ArrayTools.txtToArray(Paths.mods('data/charMenu/characterColors.txt'), tempColorArray);
            ArrayTools.txtToArray(Paths.mods('data/charMenu/characterNames.txt'), tempNameArray);
            ArrayTools.txtToArray(Paths.mods('data/charMenu/characterOffsets.txt'), tempOffsetArray);
        }

        var modList = Mods.getModDirectories();
        for (mod in 0...modList.length) {
            var modName:String = modList[mod];
            var modPath:String = Paths.mods();
            if (modName != '' || modName != null) modPath = Paths.mods(modName + '/');
            if (FileSystem.exists(modPath + 'data/charMenu/')) {
                ArrayTools.txtToArray(modPath + 'data/charMenu/characterColors.txt', tempColorArray);
                ArrayTools.txtToArray(modPath + 'data/charMenu/characterNames.txt', tempNameArray);
                ArrayTools.txtToArray(modPath + 'data/charMenu/characterOffsets.txt', tempOffsetArray);
            }
        }

        for (i in 0...tempColorArray.length) {
            var smolArray:Array<String> = tempColorArray[i].split(":");
            allColors.push([smolArray[0],smolArray[1]]);
        }

        for (i in 0...tempNameArray.length) {
            var smolArray:Array<String> = tempNameArray[i].split(":");
            characterNames.push([smolArray[0],smolArray[1]]);
        }

        for (i in 0...tempOffsetArray.length) { // I specifically hate this 'for' statement
            var smolArray:Array<String> = tempOffsetArray[i].split(":");
            var smollerArray:Array<String> = smolArray[1].split(",");
            allOffsets.push([smolArray[0],smollerArray[0],smollerArray[1]]);
        }
    }

    function clearAllSaveData() {// WARNING, ONLY USE WHEN NEEDING FRESH SAVE DATA FOR CHAR MENU
        FlxG.save.data.maxCharacters = null;
        FlxG.save.data.unlockedCharacters = null;
        FlxG.save.data.charactersAvailable = null;
        FlxG.save.flush();
    }

    function resetCharSelectVars() {
        // Only uncoment this to force the save variables to be null and potentially fix a save data issue, comment again after use
        // clearAllSaveData();
        if (FlxG.save.data.maxCharacters == null) FlxG.save.data.maxCharacters = 0;
        if (FlxG.save.data.unlockedCharacters == null) FlxG.save.data.unlockedCharacters = getUnlockedChars();
        if (FlxG.save.data.charactersAvailable == null || characterList == null || characterList == [] || characterLocks == [] || characterLocks == null || characterLocks != FlxG.save.data.charactersAvailable || FlxG.save.data.maxCharacters != characterList.length  || FlxG.save.data.unlockedCharacters != defaultUnlocked) 
            forceCharUnlockSaveUpdate();
    }

    public static function newMenu(menu:Int) {
        // Putting any number higher than 6 or lower than 0 will provide the default menu;
        switch (menu) {
            case 0:
                LoadingState.loadAndSwitchState(new CharacterMenu(['bf', 'gf', 'enemy']));
            case 1:
                LoadingState.loadAndSwitchState(new CharacterMenu(['bf', 'gf']));
            case 2:
                LoadingState.loadAndSwitchState(new CharacterMenu(['bf', 'enemy']));
            case 3:
                LoadingState.loadAndSwitchState(new CharacterMenu(['gf', 'enemy']));
            case 4:
                LoadingState.loadAndSwitchState(new CharacterMenu(['bf']));
            case 5:
                LoadingState.loadAndSwitchState(new CharacterMenu(['gf']));
            case 6:
                LoadingState.loadAndSwitchState(new CharacterMenu(['enemy']));
            default:
                LoadingState.loadAndSwitchState(new CharacterMenu(null));
        }
    }
}