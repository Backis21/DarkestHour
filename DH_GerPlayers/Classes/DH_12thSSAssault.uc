//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_12thSSAssault extends DH_12thSS;

defaultproperties
{
    MyName="Assault Trooper"
    AltName="Sto�truppe"
    Article="an "
    PluralName="Assault Troopers"
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_STG44Weapon',AssociatedAttachment=class'ROInventory.ROSTG44AmmoPouch')
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_MP40Weapon',AssociatedAttachment=class'ROInventory.ROMP40AmmoPouch')
    Grenades(0)=(Item=class'DH_Weapons.DH_StielGranateWeapon')
    Headgear(0)=class'DH_GerPlayers.DH_SSHelmetOne'
    Headgear(1)=class'DH_GerPlayers.DH_SSHelmetTwo'
    Limit=4
}
