//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_WSSGreatcoatAssault extends DH_WaffenSSGreatcoat;

defaultproperties
{
     MyName="SS Assault Troop"
     AltName="Sto�truppe-SS"
     Article="a "
     PluralName="SS Assault Troops"
     PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_STG44Weapon',AssociatedAttachment=class'ROInventory.ROSTG44AmmoPouch')
     PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_MP40Weapon',AssociatedAttachment=class'ROInventory.ROMP40AmmoPouch')
     Grenades(0)=(Item=class'DH_Weapons.DH_StielGranateWeapon')
     Headgear(0)=class'DH_GerPlayers.DH_HeerHelmetThree'
     Headgear(1)=class'DH_GerPlayers.DH_HeerHelmetTwo'
     Limit=4
}
