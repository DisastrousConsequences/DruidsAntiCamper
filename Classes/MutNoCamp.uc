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

class MutNoCamp extends Mutator;

var bool doOutOfBounds;
var string MapName;

function PreBeginPlay()
{
	local int x;
	local array<string> NoOutOfBoundsMaps;

	super.PreBeginPlay();
	NoOutOfBoundsMaps = class'NoCampInv'.default.NoOutOfBoundsMaps;

	MapName = Left(string(Level), InStr(string(Level), "."));

	doOutOfBounds = true;

	for(x = 0; x < NoOutOfBoundsMaps.length; x++)
	{
		if(MapName == NoOutOfBoundsMaps[x])
		{
			doOutOfBounds = false;
			break;
		}
	}
}

function ModifyPlayer(Pawn Other)
{
	Local NoCampInv NoCampInv;

	super.ModifyPlayer(Other);
	if (Other.Controller == None || !Other.Controller.bIsPlayer)
		return;

	if(Other.FindInventoryType(class'NoCampInv') == None)
	{
//log("NoCamp: Given to player:"@Other);
		NoCampInv = Other.Spawn(class'NoCampInv');
		NoCampInv.doOutOfBounds = doOutOfBounds;
		NoCampInv.giveTo(Other);
		NoCampInv.SetTimer(1, true);
		NoCampInv.mapname = MapName;
		NoCampInv.KarmaPointsScore = rand(NoCampInv.KarmaPointsSeed);
	}
}

defaultproperties
{
     GroupName="AntiCamper"
     FriendlyName="Druids Anti Camper"
     Description="Forces the players not to camp special objects, and keeps the players in bounds."
}