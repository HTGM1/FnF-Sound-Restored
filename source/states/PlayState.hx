package states;

import data.Discord.DiscordClient;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import data.*;
import data.SongData.SwagSong;
import data.SongData.SwagSection;
import data.chart.*;
import data.GameData.MusicBeatState;
import gameObjects.*;
import gameObjects.hud.*;
import gameObjects.hud.note.*;
import shaders.*;
import states.editors.*;
import states.menu.*;
import subStates.*;

using StringTools;

class PlayState extends MusicBeatState
{
	// song stuff
	public static var SONG:SwagSong;
	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var musicList:Array<FlxSound> = [];

	public static var songLength:Float = 0;
	
	// story mode stuff
	public static var playList:Array<String> = [];
	public static var curWeek:String = '';
	public static var isStoryMode:Bool = false;
	public static var weekScore:Int = 0;

	// extra stuff
	public static var songDiff:String = "normal";
	public static var assetModifier:String = "base";
	public static var health:Float = 1;
	// score, misses, accuracy and other stuff
	// are on the Timings.hx class!!

	// objects
	public var stageBuild:Stage;

	public var characters:Array<Character> = [];
	public var dad:Character;
	public var boyfriend:Character;
	public var gf:Character;

	// strumlines
	public var strumlines:FlxTypedGroup<Strumline>;
	public var bfStrumline:Strumline;
	public var dadStrumline:Strumline;

	// hud
	public var hudBuild:HudClass;

	// cameras!!
	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camStrum:FlxCamera;
	public var camOther:FlxCamera; // used so substates dont collide with camHUD.alpha or camHUD.visible
	public static var defaultCamZoom:Float = 1.0;

	public var camFollow:FlxObject = new FlxObject();

	public static var paused:Bool = false;

	function resetStatics()
	{
		health = 1;
		defaultCamZoom = 1.0;
		assetModifier = "base";
		Timings.init();
		paused = false;
	}

	override public function create()
	{
		super.create();
		CoolUtil.playMusic();
		resetStatics();
		if(SONG == null)
			SONG = SongData.loadFromJson("ugh");

		if(SONG.song.toLowerCase() == "collision")
			assetModifier = "pixel";

		// preloading stuff
		Paths.preloadPlayStuff();
		Rating.preload(assetModifier);
		SplashNote.resetStatics();

		// adjusting the conductor
		Conductor.setBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

		// setting up the cameras
		camGame = new FlxCamera();
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alphaFloat = 0;

		camStrum = new FlxCamera();
		camStrum.bgColor.alpha = 0;

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		// adding the cameras
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camStrum, false);
		FlxG.cameras.add(camOther, false);

		// default camera
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		//camGame.zoom = 0.6;

		stageBuild = new Stage();
		stageBuild.reloadStageFromSong(SONG.song);
		add(stageBuild);

		camGame.zoom = defaultCamZoom;
		hudBuild = new HudClass();
		hudBuild.setAlpha(0);

		/*
		*	if you want to change characters
		*	use changeChar(charVar, "new char");
		*	dont do it for non-singers tho (like gf)
		*	because it reloads the hud icons
		*/
		gf = new Character();
		changeChar(gf, "gf", false);
		
		dad = new Character();
		changeChar(dad, SONG.player2);

		boyfriend = new Character();
		boyfriend.isPlayer = true;
		changeChar(boyfriend, SONG.player1);

		// also updates the characters positions
		changeStage(stageBuild.curStage);

		characters.push(gf);
		characters.push(dad);
		characters.push(boyfriend);

		// basic layering ig
		var addList:Array<FlxBasic> = [];

		for(char in characters)
		{
			if(char.curChar == gf.curChar && char != gf)
			{
				changeChar(char, gf.curChar);
				char.setPosition(gf.x, gf.y);
				gf.visible = false;
			}

			addList.push(char);
		}
		addList.push(stageBuild.foreground);

		for(item in addList)
			add(item);

		hudBuild.cameras = [camHUD];
		add(hudBuild);

		// strumlines
		strumlines = new FlxTypedGroup();
		strumlines.cameras = [camStrum];
		add(strumlines);

		//strumline.scrollSpeed = 4.0; // 2.8
		var strumPos:Array<Float> = [FlxG.width / 2, FlxG.width / 4];
		var downscroll:Bool = SaveData.data.get("Downscroll");

		dadStrumline = new Strumline(strumPos[0] - strumPos[1], dad, downscroll, false, true, assetModifier);
		dadStrumline.ID = 0;
		strumlines.add(dadStrumline);

		bfStrumline = new Strumline(strumPos[0] + strumPos[1], boyfriend, downscroll, true, false, assetModifier);
		bfStrumline.ID = 1;
		strumlines.add(bfStrumline);

		if(SaveData.data.get("Middlescroll"))
		{
			dadStrumline.x -= strumPos[0]; // goes offscreen
			bfStrumline.x  -= strumPos[1]; // goes to the middle

			// whatever
			var guitar = new DistantNoteShader();
			guitar.downscroll = downscroll;
			camStrum.setFilters([new openfl.filters.ShaderFilter(cast guitar.shader)]);
		}

		for(strumline in strumlines.members)
		{
			strumline.scrollSpeed = SONG.speed;
			strumline.updateHitbox();
		}

		hudBuild.updateHitbox(bfStrumline.downscroll);

		var daSong:String = SONG.song.toLowerCase();

		inst = new FlxSound();
		inst.loadEmbedded(Paths.inst(daSong), false, false);

		vocals = new FlxSound();
		if(SONG.needsVoices)
		{
			vocals.loadEmbedded(Paths.vocals(daSong), false, false);
		}

		songLength = inst.length;
		function addMusic(music:FlxSound):Void
		{
			FlxG.sound.list.add(music);

			if(music.length > 0)
			{
				musicList.push(music);

				if(music.length < songLength)
					songLength = music.length;
			}

			music.play();
			music.stop();
		}

		addMusic(inst);
		addMusic(vocals);

		//Conductor.setBPM(160);
		Conductor.songPos = -Conductor.crochet * 5;
		
		// setting up the camera following
		//followCamera(dad);
		followCamSection(SONG.notes[0]);
		FlxG.camera.follow(camFollow, LOCKON, 1);
		FlxG.camera.focusOn(camFollow.getPosition());

		var unspawnNotesAll:Array<Note> = ChartLoader.getChart(SONG);

		for(note in unspawnNotesAll)
		{
			var thisStrumline = dadStrumline;
			for(strumline in strumlines)
			{
				if(note.strumlineID == strumline.ID)
					thisStrumline = strumline;
			}

			/*var thisStrum = thisStrumline.strumGroup.members[note.noteData];
			var thisChar = thisStrumline.character;*/

			var noteAssetMod:String = assetModifier;

			//noteAssetMod = ["base", "doido", "pixel"][FlxG.random.int(0, 2)];

			note.reloadNote(note.songTime, note.noteData, note.noteType, noteAssetMod);

			// oop

			thisStrumline.addSplash(note);

			thisStrumline.unspawnNotes.push(note);
		}

		switch(SONG.song.toLowerCase())
		{
			case "disruption":
				// faz o dad voar só na disruption
				var initialPos = [dad.x - (dad.width / 2) + 100, dad.y - 100];
				var flyTime:Float = 0;
				dad._update = function(elapsed:Float)
				{
					flyTime += elapsed * Math.PI;
					dad.y = initialPos[1] + Math.sin(flyTime) * 100;
					dad.x = initialPos[0] + Math.cos(flyTime) * 100;
					
					if(startedSong)
					{
						for(strum in dadStrumline.strumGroup)
						{
							var fuckyoubambi:Int = ((strum.strumData % 2 == 0) ? -1 : 1);
						
							strum.x = strum.initialPos.x + Math.sin(flyTime / 2) * 20 * fuckyoubambi;
							strum.y = strum.initialPos.y + Math.cos(flyTime / 2) * 20 * fuckyoubambi;
							strum.scale.x = strum.strumSize + Math.sin(flyTime / 2) * 0.3;
							strum.scale.y = strum.strumSize - Math.sin(flyTime / 2) * 0.3;
						}
						for(uNote in dadStrumline.unspawnNotes)
						{
							if(uNote.visible)
							{
								var daStrum = dadStrumline.strumGroup.members[uNote.noteData];
								uNote.scale.x = daStrum.scale.x;
								if(!uNote.isHold)
									uNote.scale.y = daStrum.scale.y;
							}
						}
					}
				}
		}

		// Updating Discord Rich Presence
		DiscordClient.changePresence("Playing: " + SONG.song.toUpperCase().replace("-", " "), null);
		
		for(strumline in strumlines.members)
		{
			var strumMult:Int = (strumline.downscroll ? 1 : -1);
			for(strum in strumline.strumGroup)
			{
				strum.y += FlxG.height / 4 * strumMult;
			}
		}
		startCountdown();
	}

	public var startedSong:Bool = false;

	public function startCountdown()
	{
		var daCount:Int = 0;
		
		var countTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			Conductor.songPos = -Conductor.crochet * (4 - daCount);
			
			if(daCount == 0)
			{
				for(strumline in strumlines.members)
				{
					var strumMult:Int = (strumline.downscroll ? 1 : -1);
					for(strum in strumline.strumGroup)
					{
						var strumData:Int = (strumline.isPlayer ? strum.strumData : 3 - strum.strumData);
						FlxTween.tween(strum, {y: strum.y - FlxG.height / 4 * strumMult}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeOut,
							startDelay: Conductor.crochet / 2 / 1000 * strumData,
						});
					}
				}
			}
			
			// when the girl say "one" the hud appears
			if(daCount == 2)
			{
				hudBuild.setAlpha(1, Conductor.crochet * 2 / 1000);
			}

			if(daCount == 4)
			{
				startSong();
			}

			if(daCount != 4)
			{
				var soundName:String = ["3", "2", "1", "Go"][daCount];

				FlxG.sound.play(Paths.sound("countdown/intro" + soundName));

				/*var hehe = new gameObjects.menu.Alphabet(0, 0, ["3", "2", "1", "GO"][daCount], true);
				hehe.cameras = [camHUD];
				hehe.screenCenter();
				hudBuild.add(hehe);*/
				if(daCount >= 1)
				{
					var countName:String = ["ready", "set", "go"][daCount - 1];

					var countSprite = new FlxSprite();
					countSprite.loadGraphic(Paths.image("hud/base/" + countName));
					countSprite.scale.set(0.65,0.65); countSprite.updateHitbox();
					countSprite.screenCenter();
					countSprite.cameras = [camHUD];
					hudBuild.add(countSprite);

					//new FlxTimer().start(Conductor.stepCrochet * 3.8 / 1000, function(tmr:FlxTimer)
					FlxTween.tween(countSprite, {alpha: 0}, Conductor.stepCrochet * 2.8 / 1000, {
						startDelay: Conductor.stepCrochet * 1 / 1000,
						onComplete: function(twn:FlxTween)
						{
							countSprite.destroy();
						}
					});
				}
			}

			//trace(daCount);

			daCount++;
		}, 5);
	}

	public function startSong()
	{
		startedSong = true;
		for(music in musicList)
		{
			music.stop();
			music.play();

			if(paused) {
				music.pause();
			}
		}
	}

	override function openSubState(state:FlxSubState)
	{
		super.openSubState(state);
		if(startedSong)
		{
			for(music in musicList)
			{
				music.pause();
			}
		}
	}

	override function closeSubState()
	{
		activateTimers(true);
		super.closeSubState();
		if(startedSong)
		{
			for(music in musicList)
			{
				music.play();
			}
			syncSong(true);
		}
	}

	// for pausing timers and tweens
	function activateTimers(apple:Bool = true)
	{
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if(!tmr.finished)
				tmr.active = apple;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if(!twn.finished)
				twn.active = apple;
		});
	}

	// checks
	public function checkNoteHit(note:Note, strumline:Strumline)
	{
		if(!note.mustMiss)
			onNoteHit(note, strumline);
		else
			onNoteMiss(note, strumline);
	}
	public function checkNoteMiss(note:Note, strumline:Strumline)
	{
		if(note.mustMiss)
			onNoteHit(note, strumline);
		else
			onNoteMiss(note, strumline);
	}

	// actual functions
	function onNoteHit(note:Note, strumline:Strumline)
	{
		var thisStrum = strumline.strumGroup.members[note.noteData];
		var thisChar = strumline.character;

		// anything else
		note.gotHeld = true;
		note.gotHit = true;
		note.missed = false;
		if(!note.isHold)
			note.visible = false;

		if(note.mustMiss) return;

		thisStrum.playAnim("confirm");

		// when the player hits notes
		vocals.volume = 1;
		if(strumline.isPlayer)
		{
			popUpRating(note, strumline, false);
		}

		if(!note.isHold)
		{
			var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
			if(noteDiff <= Timings.timingsMap.get("sick")[0] || strumline.botplay)
			{
				strumline.playSplash(note);
			}
		}

		if(thisChar != null && !note.isHold)
		{
			if(note.noteType != "no animation")
			{
				thisChar.playAnim(thisChar.singAnims[note.noteData], true);
				thisChar.holdTimer = 0;

				/*if(note.noteType != 'none')
					thisChar.playAnim('hey');*/
			}
		}
	}
	function onNoteMiss(note:Note, strumline:Strumline)
	{
		if(strumline.botplay) return;

		var thisStrum = strumline.strumGroup.members[note.noteData];
		var thisChar = strumline.character;

		note.gotHit = false;
		note.missed = true;
		note.setAlpha();

		// put global stuff inside onlyOnce
		var onlyOnce:Bool = false;

		if(!note.isHold)
			onlyOnce = true;
		else
		{
			if(!note.isHoldEnd && note.parentNote.gotHit)
				onlyOnce = true;
		}

		if(onlyOnce)
		{
			vocals.volume = 0;

			FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);

			if(thisChar != null && note.noteType != "no animation")
			{
				thisChar.playAnim(thisChar.missAnims[note.noteData], true);
				thisChar.holdTimer = 0;
			}

			// when the player misses notes
			if(strumline.isPlayer)
			{
				popUpRating(note, strumline, true);
			}
		}
	}
	function onNoteHold(note:Note, strumline:Strumline)
	{
		// runs until you hold it enough
		if(note.holdHitLength > note.holdLength) return;
		
		var thisStrum = strumline.strumGroup.members[note.noteData];
		var thisChar = strumline.character;
		
		vocals.volume = 1;
		thisStrum.playAnim("confirm");
		
		// DIE!!!
		if(note.mustMiss)
			health -= 0.005;

		if(note.noteType != "no animation")
		{
			thisChar.playAnim(thisChar.singAnims[note.noteData], true);
			thisChar.holdTimer = 0;
		}
	}

	public function popUpRating(note:Note, strumline:Strumline, miss:Bool = false)
	{
		var noteDiff:Float = Math.abs(note.songTime - Conductor.songPos);
		if(note.isHold && !miss)
			noteDiff = 0;

		var rating:String = Timings.diffToRating(noteDiff);
		var judge:Float = Timings.diffToJudge(noteDiff);
		if(miss)
		{
			rating = "miss";
			judge = Timings.timingsMap.get('miss')[1];
		}

		// handling stuff
		health += 0.05 * judge;
		Timings.score += Math.floor(100 * judge);
		Timings.addAccuracy(judge);

		if(miss)
		{
			Timings.misses++;

			if(Timings.combo > 0)
				Timings.combo = 0;
			Timings.combo--;
		}
		else
		{
			if(Timings.combo < 0)
				Timings.combo = 0;
			Timings.combo++;

			if(rating == "shit")
			{
				//note.onMiss();
				// forces a miss anyway
				onNoteMiss(note, strumline);
			}
		}

		var daRating = new Rating(rating, Timings.combo, note.assetModifier);

		if(SaveData.data.get("Ratings on HUD"))
		{
			hudBuild.add(daRating);
			
			for(item in daRating.members)
				item.cameras = [camHUD];

			var daX:Float = (FlxG.width / 2) - 64;
			if(SaveData.data.get("Middlescroll"))
				daX -= FlxG.width / 4;

			daRating.setPos(daX, FlxG.height / 2);
		}
		else
		{
			add(daRating);

			daRating.setPos(
				boyfriend.x + boyfriend.ratingsOffset.x,
				boyfriend.y + boyfriend.ratingsOffset.y
			);
		}

		hudBuild.updateText();
	}
	
	var pressed:Array<Bool> 	= [];
	var justPressed:Array<Bool> = [];
	var released:Array<Bool> 	= [];
	
	var playerSinging:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		camGame.followLerp = elapsed * 3;

		if(Controls.justPressed("PAUSE"))
		{
			pauseSong();
		}

		if(Controls.justPressed("RESET"))
			startGameOver();

		if(FlxG.keys.justPressed.SEVEN)
		{
			if(ChartingState.SONG.song != SONG.song)
				ChartingState.curSection = 0;
			
			ChartingState.songDiff = songDiff;

			ChartingState.SONG = SONG;
			Main.switchState(new ChartingState());
		}
		if(FlxG.keys.justPressed.EIGHT)
		{
			var char = dad;
			if(FlxG.keys.pressed.SHIFT)
				char = boyfriend;

			Main.switchState(new CharacterEditorState(char.curChar));
		}

		/*if(FlxG.keys.justPressed.SPACE)
		{
			for(strumline in strumlines.members)
			{
				strumline.downscroll = !strumline.downscroll;
				strumline.updateHitbox();
			}
			hudBuild.updateHitbox(bfStrumline.downscroll);
		}*/

		//strumline.scrollSpeed = 2.8 + Math.sin(FlxG.game.ticks / 500) * 1.5;

		//if(song.playing)
		//	Conductor.songPos = song.time;
		// syncSong
		Conductor.songPos += elapsed * 1000;

		pressed = [
			Controls.pressed("LEFT"),
			Controls.pressed("DOWN"),
			Controls.pressed("UP"),
			Controls.pressed("RIGHT")
		];
		justPressed = [
			Controls.justPressed("LEFT"),
			Controls.justPressed("DOWN"),
			Controls.justPressed("UP"),
			Controls.justPressed("RIGHT")
		];
		released = [
			Controls.released("LEFT"),
			Controls.released("DOWN"),
			Controls.released("UP"),
			Controls.released("RIGHT")
		];
		
		playerSinging = false;
		
		// strumline handler!!
		for(strumline in strumlines.members)
		{
			for(strum in strumline.strumGroup)
			{
				if(strumline.isPlayer && !strumline.botplay)
				{
					if(pressed[strum.strumData])
					{
						if(!["pressed", "confirm"].contains(strum.animation.curAnim.name))
							strum.playAnim("pressed");
					}
					else
						strum.playAnim("static");
					
					if(strum.animation.curAnim.name == "confirm")
						playerSinging = true;
				}
				else
				{
					// how botplay handles it
					if(strum.animation.curAnim.name == "confirm"
					&& strum.animation.curAnim.finished)
						strum.playAnim("static");
				}
			}

			for(unsNote in strumline.unspawnNotes)
			{
				var spawnTime:Int = 1000;
				if(strumline.scrollSpeed <= 1.5)
					spawnTime = 5000;

				if(unsNote.songTime - Conductor.songPos <= spawnTime && !unsNote.spawned)
				{
					unsNote.spawned = true;
					strumline.addNote(unsNote);
				}
			}
			for(note in strumline.allNotes)
			{
				var despawnTime:Int = 300;
				
				if(Conductor.songPos >= note.songTime + note.holdLength + Conductor.crochet + despawnTime)
				{
					if(!note.gotHit && !note.missed)
						checkNoteMiss(note, strumline);
					
					strumline.removeNote(note);
				}
			}

			// downscroll
			var downMult:Int = (strumline.downscroll ? -1 : 1);

			for(note in strumline.noteGroup)
			{
				var thisStrum = strumline.strumGroup.members[note.noteData];

				note.x = thisStrum.x + note.noteOffset.x;
				note.y = thisStrum.y + (thisStrum.height / 12 * downMult) + (note.noteOffset.y * downMult);
				
				// adjusting
				note.y += downMult * ((note.songTime - Conductor.songPos) * (strumline.scrollSpeed * 0.45));

				if(Conductor.songPos >= note.songTime + Timings.timingsMap.get("good")[0]
				&& !note.gotHit && !note.missed)
				{
					checkNoteMiss(note, strumline);
				}

				if(strumline.botplay)
				{
					if(note.songTime - Conductor.songPos <= 0 && !note.gotHit)
					{
						if(!note.mustMiss)
							checkNoteHit(note, strumline);
					}
				}

				// whatever
				if(note.scrollSpeed != strumline.scrollSpeed)
					note.scrollSpeed = strumline.scrollSpeed;
			}

			for(hold in strumline.holdGroup)
			{
				if(hold.scrollSpeed != strumline.scrollSpeed)
				{
					hold.scrollSpeed = strumline.scrollSpeed;

					if(!hold.isHoldEnd)
					{
						var newHoldSize:Array<Float> = [
							hold.frameWidth * hold.scale.x,
							hold.noteCrochet * (strumline.scrollSpeed * 0.45)
						];
						
						if(SaveData.data.get("Split Holds"))
							newHoldSize[1] -= 20;

						hold.setGraphicSize(
							Math.floor(newHoldSize[0]),
							Math.floor(newHoldSize[1])
						);
					}

					hold.updateHitbox();
				}

				hold.flipY = strumline.downscroll;
				if(hold.assetModifier == "base")
					hold.flipX = hold.flipY;
				
				var holdParent = hold.parentNote;
				if(holdParent != null)
				{
					var thisStrum = strumline.strumGroup.members[hold.noteData];
					
					hold.x = holdParent.x;
					hold.y = holdParent.y;
					if(!holdParent.isHold)
					{
						hold.x += holdParent.width / 2 - hold.width / 2;
						hold.y = holdParent.y + holdParent.height / 2;
						if(strumline.downscroll)
							hold.y -= hold.height;
					}
					else
					{
						if(strumline.downscroll)
							hold.y -= hold.height;
						else
							hold.y += holdParent.height;
					}
					
					if(SaveData.data.get('Split Holds'))
						hold.y += 20 * downMult;
					
					if(holdParent.gotHeld && !hold.missed)
					{
						hold.gotHeld = true;
						
						hold.holdHitLength = (Conductor.songPos - hold.songTime);
							
						var daRect = new FlxRect(
							0,
							0,
							hold.frameWidth,
							hold.frameHeight
						);
						
						var center:Float = (thisStrum.y + thisStrum.height / 2);
						if(!strumline.downscroll)
						{
							if(hold.y < center)
								daRect.y = (center - hold.y) / hold.scale.y;
						}
						else
						{
							if(hold.y + hold.height > center)
								daRect.y = ((hold.y + hold.height) - center) / hold.scale.y;
						}
						hold.clipRect = daRect;
						
						if(hold.isHoldEnd)
							onNoteHold(hold, strumline);
						
						if(hold.holdHitLength >= holdParent.holdLength - Conductor.stepCrochet)
						{
							if(hold.isHoldEnd && !hold.gotHit)
								onNoteHit(hold, strumline);
							hold.missed = false;
							hold.gotHit = true;
						}
						else if(!pressed[hold.noteData] && !strumline.botplay)
						{
							checkNoteMiss(hold, strumline);
						}
					}
					
					if(holdParent.missed && !hold.missed)
						checkNoteMiss(hold, strumline);
				}
			}

			if(justPressed.contains(true) && !strumline.botplay && strumline.isPlayer)
			{
				for(i in 0...justPressed.length)
				{
					if(justPressed[i])
					{
						var possibleHitNotes:Array<Note> = []; // gets the possible ones
						var canHitNote:Note = null;

						for(note in strumline.noteGroup)
						{
							var noteDiff:Float = (note.songTime - Conductor.songPos);

							if(noteDiff <= Timings.minTiming && !note.missed && !note.gotHit && note.noteData == i)
							{
								possibleHitNotes.push(note);
								canHitNote = note;
							}
						}

						// if the note actually exists then you got it
						if(canHitNote != null)
						{
							for(note in possibleHitNotes)
							{
								if(note.songTime < Conductor.songPos && note.mustMiss)
									continue;

								if(note.songTime < canHitNote.songTime)
									canHitNote = note;
							}

							checkNoteHit(canHitNote, strumline);
						}
						else
						{
							// ghost tapped lol
							if(!SaveData.data.get("Ghost Tapping"))
							{
								vocals.volume = 0;
								var thisChar = strumline.character;
								if(thisChar != null)
								{
									thisChar.playAnim(thisChar.missAnims[i], true);
									thisChar.holdTimer = 0;
								}

								var note = new Note();
								note.reloadNote(0,0,"none",assetModifier);
								FlxG.sound.play(Paths.sound('miss/missnote' + FlxG.random.int(1, 3)), 0.55);
								popUpRating(note, strumline, true);
							}
						}
					}
				}
			}
		}

		var lastSteps:Int = 0;
		var curSect:SwagSection = null;
		for(section in SONG.notes)
		{
			if(curStep >= lastSteps)
				curSect = section;

			lastSteps += section.lengthInSteps;
		}
		if(curSect != null)
		{
			followCamSection(curSect);
		}

		if(health <= 0)
		{
			startGameOver();
		}
		
		function lerpCamZoom(daCam:FlxCamera, target:Float = 1.0, speed:Int = 6)
			daCam.zoom = FlxMath.lerp(daCam.zoom, target, elapsed * speed);
			
		lerpCamZoom(camGame, defaultCamZoom);
		lerpCamZoom(camHUD);
		lerpCamZoom(camStrum);

		health = FlxMath.bound(health, 0, 2); // bounds the health
	}
	
	public function followCamSection(sect:SwagSection):Void
	{
		followCamera(dadStrumline.character);
		
		if(sect != null)
		{
			if(sect.mustHitSection)
				followCamera(bfStrumline.character);
		}
	}

	public function followCamera(?char:Character, ?offsetX:Float = 0, ?offsetY:Float = 0)
	{
		camFollow.setPosition(0,0);

		if(char != null)
		{
			var playerMult:Int = (char.isPlayer ? -1 : 1);

			camFollow.setPosition(char.getMidpoint().x + (200 * playerMult), char.getMidpoint().y - 20);

			camFollow.x += char.cameraOffset.x * playerMult;
			camFollow.y += char.cameraOffset.y;
		}

		camFollow.x += offsetX;
		camFollow.y += offsetY;
	}

	override function beatHit()
	{
		super.beatHit();
		for(change in Conductor.bpmChangeMap)
		{
			if(curStep >= change.stepTime && Conductor.bpm != change.bpm)
				Conductor.setBPM(change.bpm);
		}
		hudBuild.beatHit(curBeat);
		
		// hey!!
		if(SONG.song == 'bopeebo' && curBeat % 8 == 7 && curBeat > 0)
		{
			boyfriend.holdTimer = 0;
			boyfriend.playAnim("hey");
		}
		
		/*if(curBeat >= 8)
		{
			Conductor.songPos = 0;
			for(music in musicList)
				music.time = 0;
			
			for(strumline in strumlines)
				for(uNote in strumline.unspawnNotes)
					uNote.resetNote();
		}*/

		if(curBeat % 4 == 0)
		{
			zoomCamera(0.05, 0.025);
		}
		for(char in characters)
		{
			if(curBeat % 2 == 0 || char.quickDancer)
			{
				var canIdle = (char.holdTimer >= char.holdLength);
				
				if(char.isPlayer && playerSinging)
					canIdle = false;

				if(canIdle)
					char.dance();
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();
		syncSong();
		
		/*if(curBeat >= 8)
		{
			Conductor.songPos = 0;
			for(music in musicList)
				music.time = 0;
			
			for(line in strumlines.members)
			for(uNote in line.unspawnNotes)
				uNote.resetNote();
		}*/
	}

	public function syncSong(?forced:Bool = false):Void
	{
		if(!startedSong) return;

		for(music in musicList)
		{
			if(music.playing && Conductor.songPos < music.length)
			{
				if(Math.abs(Conductor.songPos - music.time) >= 40 || forced)
				{
					// makes everyone sync to the instrumental
					trace("synced song");
					Conductor.songPos = inst.time;
					
					if(music != inst)
					{
						music.time = inst.time;
						music.play();
					}
				}
			}
		}

		checkEndSong();
	}
	
	// checks if the song is allowed to end
	public function checkEndSong():Void
	{
		if(Conductor.songPos >= songLength)
			endSong();
	}
	// ends it all
	public function endSong()
	{
		Highscore.addScore(SONG.song.toLowerCase() + '-' + songDiff, {
			score: 		Timings.score,
			accuracy: 	Timings.accuracy,
			misses: 	Timings.misses,
		});
		
		weekScore += Timings.score;
		
		if(playList.length <= 0)
		{
			if(isStoryMode)
			{
				Highscore.addScore('week-$curWeek-$songDiff', {
					score: 		weekScore,
					accuracy: 	0,
					misses: 	0,
				});
			}
			
			sendToMenu();
		}
		else
		{
			SONG = SongData.loadFromJson(playList[0], songDiff);
			playList.remove(playList[0]);
			
			//trace(playList);
			Main.switchState(new PlayState());
		}
	}

	override function onFocusLost():Void
	{
		if(!paused && !isDead) pauseSong();
		super.onFocusLost();
	}

	public function pauseSong()
	{
		paused = true;
		activateTimers(false);
		openSubState(new PauseSubState());
	}

	public var isDead:Bool = false;

	public function startGameOver()
	{
		if(isDead) return;

		isDead = true;
		activateTimers(false);
		persistentDraw = false;
		openSubState(new GameOverSubState(boyfriend));
	}

	public function zoomCamera(gameZoom:Float = 0, hudZoom:Float = 0)
	{
		camGame.zoom += gameZoom;
		camHUD.zoom += hudZoom;
		camStrum.zoom += hudZoom;
	}

	// funny thingy
	public function changeChar(char:Character, newChar:String = "bf", ?iconToo:Bool = true)
	{
		// gets the original position
		var storedPos = new FlxPoint(
			char.x - char.globalOffset.x,
			char.y + char.height - char.globalOffset.y
		);
		// changes the character
		char.reloadChar(newChar);
		// puts it to the new right position
		char.setPosition(
			storedPos.x + char.globalOffset.x,
			storedPos.y - char.height + char.globalOffset.y
		);

		if(iconToo)
		{
			// updating icons
			var daID:Int = (char.isPlayer ? 1 : 0);
			hudBuild.changeIcon(daID, char.curChar);
		}
	}

	// funny thingy
	public function changeStage(newStage:String = "stage")
	{
		stageBuild.reloadStage(newStage);

		// gfpos
		gf.setPosition(stageBuild.gfPos.x, stageBuild.gfPos.y);
		gf.x -= gf.width / 2;
		gf.y -= gf.height;
		gf.visible = stageBuild.hasGf;

		dad.setPosition(stageBuild.dadPos.x, stageBuild.dadPos.y);
		dad.y -= dad.height;

		boyfriend.setPosition(stageBuild.bfPos.x, stageBuild.bfPos.y);
		boyfriend.y -= boyfriend.height;

		for(char in [gf, dad, boyfriend])
		{
			char.x += char.globalOffset.x;
			char.y += char.globalOffset.y;
		}
	}
	
	// substates also use this
	public static function sendToMenu()
	{
		if(isStoryMode)
			Main.switchState(new StoryMenuState());
		else
			Main.switchState(new FreeplayState());
	}
}