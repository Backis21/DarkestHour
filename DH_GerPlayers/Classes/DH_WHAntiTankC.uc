//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_WHAntiTankC extends DH_HeerCamo;

defaultproperties
{
    MyName="Tank Hunter"
    AltName="Panzerj�ger"
    Article="a "
    PluralName="Tank Hunters"

    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_MP40Weapon',AssociatedAttachment=class'ROInventory.ROMP40AmmoPouch')
    Grenades(0)=(Item=class'DH_Equipment.DH_NebelGranate39Weapon')
    GivenItems(0)="DH_Weapons.DH_PanzerschreckWeapon"
    Headgear(0)=class'DH_GerPlayers.DH_HeerHelmetOne'
    Headgear(1)=class'DH_GerPlayers.DH_HeerHelmetTwo'
    Limit=1
}
