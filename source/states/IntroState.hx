package states;

import hxvlc.openfl.Video;
import hxvlc.flixel.FlxVideo;
import flixel.util.FlxTimer;
import backend.game.GameData.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;

var intro:FlxVideo;
var timer:FlxTimer;

class IntroState extends MusicBeatState
{

	override public function create():Void 
	{	
		intro = new FlxVideo();
		intro.onEndReached.add(function():Void
		{
			intro.dispose();

			FlxG.removeChild(intro);
		});
		FlxG.addChildBelowMouse(intro);

		if (intro.load('assets/videos/intro.mp4'))
			intro.play();
			FlxTimer.wait(16.0, () -> Main.switchState(new states.TitleState()));
	}
	override public function update(elapsed:Float):Void 
	{

		if(Controls.justPressed(ACCEPT))
			intro.stop();
		//why?!?!?
		if(Controls.justPressed(ACCEPT))
			Main.switchState(new states.TitleState());


	}
}