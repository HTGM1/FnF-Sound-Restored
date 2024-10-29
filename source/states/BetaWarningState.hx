package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import data.GameData.MusicBeatState;
import flixel.text.FlxText;
import flixel.system.FlxSound;

class BetaWarningState extends MusicBeatState
{
	override public function create():Void 
	{
		super.create();
		var tex:String = "Keep in mind!\n\nThis mod is still in Development phases\nbe everything here is always subjected to change.\n\nPress ENTER to ACCEPT";
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
            Main.switchState(new states.TitleState());

            FlxG.save.data.beenWarned = true;
            FlxG.save.flush();
        }
	}
}