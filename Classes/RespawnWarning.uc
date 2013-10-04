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

class RespawnWarning extends LocalMessage;

static function string GetString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1,
				 optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if(Switch == 0)
		return "You have been respawned. You have no warnings remaining";
	else if(Switch == 1)
		return "You have been respawned. You have"@ switch @"respawn remaining";
	else
		return "You have been respawned. You have"@ switch @"respawns remaining";
}

defaultproperties
{
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=7
     FontSize=-1
     DrawColor=(B=0,G=0,R=200)
     PosY=0.500000
}
