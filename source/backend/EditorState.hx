package backend;

import flixel.group.FlxGroup;

class EditorState extends MusicBeatState {
	var psychInputTexts:FlxGroup = new FlxGroup();
    var psychButtons:FlxGroup = new FlxGroup();
    var psychCheckBoxes:FlxGroup = new FlxGroup();
    var psychDropDowns:FlxGroup = new FlxGroup();
    var psychNumericSteppers:FlxGroup = new FlxGroup();

    var psychBoxes:FlxGroup = new FlxGroup();
    var boxes:Array<PsychUIBox> = [];
    var boxMoved:Bool = false;
    var boxReleased:Bool = true;

    override function update(elapsed:Float) {
        super.update(elapsed);

        @:privateAccess {
            var amountMoving:Int = 0;
            var amountPressed:Int = 0;
            for (box in boxes) {
                if (box._draggingBox) amountMoving += 1;
                if (box._pressedBox) amountPressed += 1;
            }
            if (amountMoving > 0) boxMoved = true; else boxMoved = false;
            if (amountPressed == 0) boxReleased = true; else boxReleased = false;
        }
        if (FlxG.mouse.overlaps(psychButtons, FlxG.camera) || FlxG.mouse.overlaps(psychDropDowns, FlxG.camera) || FlxG.mouse.overlaps(psychNumericSteppers, FlxG.camera)) {
            Cursor.cursorMode = Pointer;
		} else if (FlxG.mouse.overlaps(psychInputTexts, FlxG.camera)) {
			Cursor.cursorMode = Text;
        } else if (FlxG.mouse.overlaps(psychCheckBoxes, FlxG.camera)) {
            Cursor.cursorMode = Cell;
        } else if (FlxG.mouse.overlaps(psychBoxes, FlxG.camera) && boxMoved || FlxG.mouse.overlaps(psychBoxes, FlxG.camera) && !boxReleased) { //Temp work around for detection cuz IDK
            Cursor.cursorMode = Grabbing;
        }  else Cursor.cursorMode = Default;
    }

    function inputTextsGroup(array:Array<PsychUIInputText>) {
		for (item in array) psychInputTexts.add(item.bg);
	}

    function buttonsGroup(array:Array<PsychUIButton>) {
        for (item in array) psychButtons.add(item.bg);
    }

    function checkBoxesGroup(array:Array<PsychUICheckBox>) {
        for (item in array) psychCheckBoxes.add(item.box);
    }

    function dropDownsGroup(array:Array<PsychUIDropDownMenu>) {
        for (item in array) psychDropDowns.add(item.button);
    } 

    function boxesGroup(array:Array<PsychUIBox>) {
        for (item in array) {
            psychBoxes.add(item.bg);
            boxes.push(item);
        }
    }

    function numericSteppersGroup(array:Array<PsychUINumericStepper>) {
        for (item in array) {
            psychNumericSteppers.add(item.buttonPlus);
            psychNumericSteppers.add(item.buttonMinus);
            psychInputTexts.add(item.bg);
        }
    }
}