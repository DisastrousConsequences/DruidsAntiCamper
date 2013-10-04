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

class NoCampMessage extends LocalMessage;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
				 optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	local NoCampInv NoCampInv;
	local string special;
	NoCampInv = NoCampInv(OptionalObject);
	if(NoCampInv != None && NoCampInv.specialObject != "")
		special = NoCampInv.specialObject;
	else
		special = "special object";


	if(switch == 1)
		return "You are too close to a" @ special $ ". You have"@ switch @"second to leave this area.";
	else
		return "You are too close to a" @ special $ ". You have"@ switch @"seconds to leave this area.";
}

defaultproperties
{
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=2
     FontSize=-1
     DrawColor=(B=0,G=0,R=200)
     PosY=0.750000
}
