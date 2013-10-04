/*
    Copyright (C) 2005  Clinton H Goudie-Nice aka TheDruidXpawX

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

class NoCampInv extends Inventory
	config(AntiCamper);

var config int SpecialObjectDistance;
var config int VisiblePawnDistance;
var config int WarnSeconds;
var config int RespawnSeconds;
var config int NumberOfRespawnsToKill;
var config array<class<Actor> > SpecialObjects;
var config array<class<Weapon> > SpecialWeapons; //hack for RPG
var config array<string> NoOutOfBoundsMaps;
var config bool DisableOutOfBounds;
var config bool DisableSpecialObjects;
var config bool CountUpInArea;
var config bool DisableNearbyOpponentsNearSpecialObjects;
var config bool CountUpAfterLeavingArea;
var config bool WarnAdmins;
var config bool abortRedeemer;
var config int MaxKarmaPointsScore;
var config int MinKarmaPointsScore;
var config int KarmaPointsSeed;

var config bool Debug;

var() name CountDown[10];

var int secondsNearSpecial;
var int secondsOffPath;
var int respawnCount;

var int SecondsInKarmaPoints;
var int KarmaPointsScore;
var bool skipNextKarmaCheck;

var bool doOutOfBounds;

var Controller Controller; //Sometimes Instigator has the controller cleared. That's no good for us.
var NavigationPoint lastAnchor; //stored in case it's cleared.
var String MapName;

var String specialObject;

replication
{
	reliable if (Role == ROLE_Authority)
		specialObject;
}

function Timer()
{
	local Actor a;
	local WeaponPickup p;
	local int x;
	local int pickupindex;
	local int dotindex;
	local bool foundSpecial;
	local bool outOfBounds;
	local bool opponentNearBy;
	local string logInfo;

	if(Instigator == None)
	{
		if(Debug) 
			log("AntiCamper: Stopped. No Instigator");
		super.Timer();
		SetTimer(0, true);
		return;
	}
	if(Instigator.bIgnoreOutOfWorld)
	{
		if(Debug) 
			log("AntiCamper: Skipped. IgnoreOutOfWorld set");
		super.Timer();
		return;
	}

	if(Controller == None && Instigator.Controller != None)
		Controller = Instigator.Controller;
	if(Controller == None)
	{
		super.Timer();
		if(Debug) 
			log("AntiCamper: Suspended. NoController:"@Controller.PlayerReplicationInfo.GetHumanReadableName());
		return; //Something is amiss. It should get worked out shortly
	}	
	if(Controller.Pawn != none && Controller.Pawn.Anchor != none)
		lastAnchor = Controller.Pawn.Anchor;

	if(!WarnAdmins && Controller != None && Controller.PlayerReplicationInfo != None && Controller.PlayerReplicationInfo.bAdmin)
	{
		super.Timer();
		if(Debug) 
			log("AntiCamper: Suspended. Admin:"@Controller.PlayerReplicationInfo.GetHumanReadableName());
		return; //we dont check for admins.
	}

	if(Controller.Pawn != None && Controller.Pawn.isA('RedeemerWarhead') && !abortRedeemer)
	{
		super.Timer();
		if(Debug) 
			log("AntiCamper: Suspended. Redeemer:"@Controller.PlayerReplicationInfo.GetHumanReadableName());
		return; //told not to abort redeemers.
	}
	
	if(!skipNextKarmaCheck)
	{
		if(KarmaPointsScore < MinKarmaPointsScore)
			KarmaPointsScore = MinKarmaPointsScore;
		if(KarmaPointsScore > MaxKarmaPointsScore)
			KarmaPointsScore = MaxKarmaPointsScore;
		if(KarmaPointsScore > 0)
		{
			if(SecondsInKarmaPoints < KarmaPointsScore)
			{
				SecondsInKarmaPoints++;
				super.Timer();
				if(Debug) 
					log("AntiCamper: Suspended. Enough KarmaPoints For:"@Controller.PlayerReplicationInfo.GetHumanReadableName());
				return;
			}
			else
				SecondsInKarmaPoints=0; //The server needs to perofrm its checks this time.
		}
	}
	else
	{
		skipNextKarmaCheck = false;
		SecondsInKarmaPoints=0;
	}

	foundSpecial = false;
	if(!DisableSpecialObjects)
	{
		if(SpecialObjects.length > 0)
		{
			for(x = 0; !foundSpecial && x < SpecialObjects.length; x++)
			{
				foreach Instigator.VisibleCollidingActors(SpecialObjects[x], a, SpecialObjectDistance)
				{
					foundSpecial = true;
					specialObject = string(a.Class);

					pickupindex = InStr(specialObject, "Pickup");
					if(pickupindex > -1)
						specialObject = Left(specialObject, pickupindex);
					
					dotindex = InStr(specialObject, ".");
					if(dotindex > -1)
						specialObject = Right(specialObject, len(specialObject) - (dotindex + 1));
					break;
				}
			}
		}

		if(SpecialWeapons.length > 0)
		{
			if(!foundSpecial && SpecialWeapons.length > 0)
			{
				foreach Instigator.VisibleCollidingActors(class'WeaponPickup', p, SpecialObjectDistance)
				{
					for(x = 0; x < SpecialWeapons.length; x++)
					{
						if(p.InventoryType == SpecialWeapons[x])
						{
							foundSpecial = true;
							specialObject = string(SpecialWeapons[x]);

							dotindex = InStr(specialObject, ".");
							if(dotindex > -1)
								specialObject = Right(specialObject, len(specialObject) - (dotindex + 1));

							break;
						}
					}
		
					if(foundSpecial)
						break;
				}
			}
		}
	}
	
	if
	(
		!DisableOutOfBounds && 
		doOutOfBounds && 
		(
			Controller.FindRandomDest() == None && (lastAnchor != none && Controller.FindPathToward(lastAnchor) == None)
		)
	)
	{
		outOfBounds = true;
		if(Debug) 
			log("Anchor is:"@Controller.Pawn.Anchor);
	}


	if(!Level.Game.bGameEnded && ((foundSpecial && !DisableNearbyOpponentsNearSpecialObjects) || outOfBounds)) //only do this check if we need to.
	{
		if 
		(
			outOfBounds &&
			Controller.Pawn != None && 
			Controller.Pawn.Base != None && 
			Controller.Pawn.Base.IsA('BlockingVolume') && 
			!Controller.Pawn.Base.bBlockZeroExtentTraces
		)
		{
			// the problem here is that they can see the monster, 
			// and it can see them, but they're literally walking on air.
			// and the monster may not be able to shoot through this "air"
			opponentNearBy = false;
		}
		else
			opponentNearBy = isOpponentNearBy();
	}

	if(Debug) 
		log(
			"AntiCamper:"@Controller.PlayerReplicationInfo.GetHumanReadableName()@
			"foundSpecial"@foundSpecial@
			"outOFBounds"@outOfBounds@
			"SecondsNearSpecial"@SecondsNearSpecial@
			"secondsOffPath"@secondsOffPath@
			"opponentNearBy"@opponentNearBy@
			"bGameEnded"@Level.Game.bGameEnded
		);

	if(!foundSpecial || Level.Game.bGameEnded)
	{
		if(CountUpAfterLeavingArea && SecondsNearSpecial > 0)
			SecondsNearSpecial--;
		else
			SecondsNearSpecial = 0;

		specialObject = "";
	}
	else
	{
		if(opponentNearBy)
		{
			if(CountUpInArea && secondsNearSpecial >= WarnSeconds)
				secondsNearSpecial--;
		}
		else
		{
			SecondsNearSpecial++;
			KarmaPointsScore --;
			skipNextKarmaCheck = true;
			if (secondsOffPath <= secondsNearSpecial && PlayerController(Controller) != None && secondsNearSpecial >= WarnSeconds)
			{
				if(Controller.Pawn != None && Controller.Pawn.isA('RedeemerWarhead'))
					RedeemerWarhead(Controller.Pawn).Destroy();
		
				if(RespawnSeconds - secondsNearSpecial > 0)
					PlayerController(Controller).
						ReceiveLocalizedMessage(class 'NoCampMessage', RespawnSeconds - secondsNearSpecial,,, self);

				if(RespawnSeconds - secondsNearSpecial <= 10 && RespawnSeconds - secondsNearSpecial > 0)
				{
					KarmaPointsScore=KarmaPointsScore-4;
					PlayerController(Controller).
						QueueAnnouncement
						(
							CountDown[RespawnSeconds - secondsNearSpecial -1], 
							1, 
							AP_InstantOrQueueSwitch, 
							1 
						);
				}
			}
		}
	}
	
	if(!outOfBounds || Level.Game.bGameEnded)
	{
		if(CountUpAfterLeavingArea && secondsOffPath > 0)
			secondsOffPath--;
		else
			secondsOffPath = 0;
	}
	else
	{
		if(opponentNearBy)
		{
			if(CountUpInArea && secondsOffPath >= WarnSeconds)
				secondsOffPath--;
		}
		else
		{
			secondsOffPath++; //outside the map.
			KarmaPointsScore --;
			skipNextKarmaCheck = true;
			if (secondsOffPath > secondsNearSpecial && PlayerController(Controller) != None && secondsOffPath >= WarnSeconds)
			{
				if(Controller.Pawn != None && Controller.Pawn.isA('RedeemerWarhead'))
					RedeemerWarhead(Controller.Pawn).Destroy();

				if(RespawnSeconds - secondsOffPath > 0)
					PlayerController(Controller).
						ReceiveLocalizedMessage(class 'OutOfBoundsMessage', RespawnSeconds - secondsOffPath,,, self);

				if(RespawnSeconds - secondsOffPath <= 10 && RespawnSeconds - secondsOffPath > 0)
				{
					KarmaPointsScore=KarmaPointsScore-4;
					PlayerController(Controller).
						QueueAnnouncement
						(
							CountDown[RespawnSeconds - secondsOffPath -1], 
							1, 
							AP_InstantOrQueueSwitch, 
							1 
						);
				}
			}
		}
	}

	if(secondsNearSpecial >= RespawnSeconds)
	{
		loginfo = "name="$Controller.PlayerReplicationInfo.GetHumanReadableName()@
                          "id="$PlayerController(Controller).GetPlayerIDHash()@
                          "map="$MapName;
		if(respawnCount >= NumberOfRespawnsToKill)
		{
			log("AntiCamper:"@loginfo@"was killed for camping.");
			Instigator.died(Controller, Class'DamTypeCamper', Instigator.Location);
		}
		else
		{
			log("AntiCamper:"@loginfo@"was respawned for camping.");
			respawnInstigator();
		}
	}
	else if(secondsOffPath >= RespawnSeconds)
	{
		loginfo = "name="$Controller.PlayerReplicationInfo.GetHumanReadableName()@
                          "id="$PlayerController(Controller).GetPlayerIDHash()@
                          "map="$MapName;
		if(respawnCount >= NumberOfRespawnsToKill)
		{
			log("AntiCamper:"@loginfo@"was killed for being out of bounds.");
			Instigator.died(Controller, Class'DamTypeOutOfBounds', Instigator.Location);
		}
		else
		{
			log("AntiCamper:"@loginfo@"was respawned for being out of bounds.");
			respawnInstigator();
		}
	}
	if(secondsOffPath <= 0 && secondsNearSpecial <= 0 && !opponentNearBy)
		KarmaPointsScore ++; //they're not in any odd territory.

	super.Timer();
}

function respawnInstigator()
{
	Local int team;
	local int EffectNum;
	local NavigationPoint SpawnPoint;
	local Vector ReviveLocation;
	local Vector PreviousLocation;
	KarmaPointsScore = MinKarmaPointsScore; //they need to build their karma points back up on this one

	if(Instigator.getTeam() != None)
		team = Instigator.getTeam().TeamIndex;
	else
		team = 255;
	respawnCount ++;
	
	if(Controller.Pawn != None && Controller.Pawn.isA('Vehicle'))
		Vehicle(Controller.Pawn).EjectDriver();
	if(Controller.Pawn != None && Controller.Pawn.isA('RedeemerWarhead'))
		RedeemerWarhead(Controller.Pawn).Destroy();

	if (Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.HasFlag != None)
		Instigator.PlayerReplicationInfo.HasFlag.Drop(0.5 * Instigator.Velocity);

	SpawnPoint = Level.Game.FindPlayerStart(Controller, team);
	ReviveLocation = SpawnPoint.Location + vect(0,0,40);
	PreviousLocation = Instigator.Location;

	Instigator.SetLocation(ReviveLocation);
	xPawn(Instigator).DoTranslocateOut(PreviousLocation);
	if (Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None)
		EffectNum = Instigator.PlayerReplicationInfo.Team.TeamIndex;
	Instigator.SetOverlayMaterial(class'TransRecall'.default.TransMaterials[EffectNum], 1.0, false);
	Instigator.PlayTeleportEffect(false, false);
	secondsOffPath = 0;
	secondsNearSpecial = 0;
	PlayerController(Controller).
		ReceiveLocalizedMessage(class 'RespawnWarning', NumberOfRespawnsToKill - respawnCount,,, self);
}

function bool isOpponentNearby()
{
	local Pawn Pawn;
	local Pawn SubPawn;

	foreach Instigator.VisibleCollidingActors(class'Pawn', Pawn, VisiblePawnDistance)
	{
		if(Pawn == None || Pawn == Instigator || Pawn.Controller == None)
			continue;
		if(Pawn.isA('Vehicle') && Vehicle(Pawn).Driver == None)
			Continue;
		//ok, this is a real live pawn.
		if
		(
			Instigator.getTeam() == None ||
			Pawn.getTeam() == None ||
			Pawn.getTeam().TeamIndex != Instigator.getTeam().TeamIndex
		)
		{
			if(Debug) 
				log(
					"AntiCamper: Nearby Pawn:"@Controller.PlayerReplicationInfo.GetHumanReadableName()@
					"AntiCamper Nearby Pawn:"@Pawn.Controller.PlayerReplicationInfo.GetHumanReadableName()@":"@Pawn.class
				);
			//This pawn could disqualify the out of bounds.
			//I can see them, but can they see me? This happens due to map flaws.
			foreach Pawn.VisibleCollidingActors(class'Pawn', SubPawn, VisiblePawnDistance)
				if(SubPawn == Instigator || SubPawn.isA('Vehicle') && Vehicle(SubPawn).Driver == Instigator)
				{
					skipNextKarmaCheck = true;
					//if I had to do this, take away a karma point. They're out of bounds or near a special object.
					//Even if they wont be actively warned about it, they're still in "questionable territory."
					karmaPointsScore--;
					return true;
				}
		}
	
	}
	return false;
}

function DropFrom(vector StartLocation)
{
	//this inventory cant be dropped.
}

defaultproperties
{
     SpecialObjectDistance=1500
     VisiblePawnDistance=6000
     NumberOfRespawnsToKill=1
     WarnSeconds=15
     WarnAdmins=true
     RespawnSeconds=25
     CountUpInArea=true
     CountUpAfterLeavingArea=false
     abortRedeemer=false
     MaxKarmaPointsScore=15
     MinKarmaPointsScore=-50
     KarmaPointsSeed=15

     RemoteRole=ROLE_DumbProxy

     bOnlyRelevantToOwner=True
     bAlwaysRelevant=True
     bReplicateInstigator=False

     CountDown(0)=One
     CountDown(1)=Two
     CountDown(2)=Three
     CountDown(3)=Four
     CountDown(4)=Five
     CountDown(5)=Six
     CountDown(6)=Seven
     CountDown(7)=Eight
     CountDown(8)=Nine
     CountDown(9)=Ten

     Debug=false
}