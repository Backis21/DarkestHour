//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_BritishMortarObserverOx_Bucks extends DH_Ox_Bucks;

function class<ROHeadgear> GetHeadgear()
{
    if (FRand() < 0.2)
    {
        if (FRand() < 0.5)
            return Headgear[2];
        else
            return Headgear[1];
    }
    else
        return Headgear[0];
}

defaultproperties
{
    bIsMortarObserver=true
    MyName="Mortar Observer"
    AltName="Mortar Observer"
    Article="a "
    PluralName="Mortar Observers"
    InfoText="The mortar observer is tasked with assisting the mortar operator by acquiring and marking targets using his binoculars.  Targets marked by the mortar observer will be relayed to the mortar operator."
    MenuImage=texture'DHBritishCharactersTex.Icons.Brit_MortarObserver'
    Models(0)="para1"
    Models(1)="para2"
    Models(2)="para3"
    Models(3)="para4"
    Models(4)="para5"
    Models(5)="para6"
    SleeveTexture=texture'DHBritishCharactersTex.Sleeves.Brit_Para_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo4Weapon',Amount=6)
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo2Weapon',Amount=1)
    Grenades(0)=(Item=class'DH_Weapons.DH_M1GrenadeWeapon',Amount=2)
    GivenItems(0)="DH_Engine.DH_BinocularsItem"
    Headgear(0)=class'DH_BritishPlayers.DH_BritishParaHelmet1'
    Headgear(1)=class'DH_BritishPlayers.DH_BritishParaHelmet2'
    Headgear(2)=class'DH_BritishPlayers.DH_BritishParaHelmet1'
}
