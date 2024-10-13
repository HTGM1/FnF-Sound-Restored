package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
//import flixel.addons.effects.FlxSkewedSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import states.PlayState;

class Stage extends FlxGroup
{
	public var curStage:String = "";

	// things to help your stage get better
	public var bfPos:FlxPoint  = new FlxPoint();
	public var dadPos:FlxPoint = new FlxPoint();
	public var gfPos:FlxPoint  = new FlxPoint();
	public var gfVersion:String = "";

	public var foreground:FlxGroup;

	public function new() {
		super();
		foreground = new FlxGroup();
	}

	public function reloadStageFromSong(song:String = "test"):Void
	{
		var stageList:Array<String> = [];
		
		stageList = switch(song)
		{
			default: ["stage"];
			
			//case "template": ["preload1", "preload2", "starting-stage"];
		};
		
		/*
		*	makes changing stages easier by preloading
		*	a bunch of stages at the create function
		*	(remember to put the starting stage at the last spot of the array)
		*/
		for(i in stageList)
			reloadStage(i);
	}

	public function reloadStage(curStage:String = "")
	{
		this.clear();
		foreground.clear();
		
		gfPos.set(660, 580);
		/*dadPos.set(100,700);
		bfPos.set(850, 700);*/
		dadPos.set(260, 700);
		bfPos.set(1100, 700);
		gfVersion = getGfVersion(curStage);
		// setting gf to "" makes her invisible
		
		PlayState.defaultCamZoom = 1.0;
		
		this.curStage = curStage;
		switch(curStage)
		{
			default:
				this.curStage = "stage";
				PlayState.defaultCamZoom = 0.9;
				
				var bg = new FlxSprite(-600, -200).loadGraphic(Paths.image("backgrounds/stage/stageback"));
				bg.scrollFactor.set(0.75,0.75);
				add(bg);
				
				var front = new FlxSprite(-580, 440);
				front.loadGraphic(Paths.image("backgrounds/stage/stagefront"));
				add(front);
				
				var curtains = new FlxSprite(-600, -400).loadGraphic(Paths.image("backgrounds/stage/stagecurtains"));
				curtains.scrollFactor.set(1.4,1.4);
				foreground.add(curtains);
		}
	}

	public function getGfVersion(curStage:String)
	{
		return switch(curStage)
		{
			case "school"|"school-evil": "gf-pixel";
			default: "gf";
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	public function stepHit(curStep:Int = -1)
	{
		// put your song stuff here
		
		// beat hit
		if(curStep % 4 == 0)
		{
			
		}
	}
}