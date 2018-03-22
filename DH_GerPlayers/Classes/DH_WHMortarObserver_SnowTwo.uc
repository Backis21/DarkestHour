//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_WHMortarObserver_SnowTwo extends DH_HeerSnowTwo;

defaultproperties
{
    bIsMortarObserver=true
    MyName="Artillery Observer"
    AltName="Artilleriebeobachter"
    Article="a "
    PluralName="Artillery Observers"

    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_Kar98Weapon',AssociatedAttachment=class'ROInventory.ROKar98AmmoPouch')
    Grenades(0)=(Item=class'DH_Weapons.DH_StielGranateWeapon')
    GivenItems(0)="DH_Equipment.DHBinocularsItem"
    Limit=1
}
