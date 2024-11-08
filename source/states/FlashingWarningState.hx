package states;

import backend.game.GameData.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class FlashingWarningState extends MusicBeatState
{
	override public function create():Void 
	{
		super.create();
		var tex:String = "Warning!\n\nThis mod features flashing lights that may\nbe harmful to those with photosensitivity.\nYou can disable them in the Options menu.\n\nPress ENTER tp ACCEPT";
		var popUpTxt = new FlxText(0,0,0,tex);
		popUpTxt.setFormat(Main.gFont, 36, 0xFFFFFFFF, CENTER);
		popUpTxt.screenCenter();
		add(popUpTxt);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if(Controls.justPressed(ACCEPT))
		{
            Main.switchState(new states.BetaWarningState());

            FlxG.save.data.beenWarned = true;
            FlxG.save.flush();
        }
	}
}