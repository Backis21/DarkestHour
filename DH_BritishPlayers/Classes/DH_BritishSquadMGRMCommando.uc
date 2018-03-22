//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_BritishSquadMGRMCommando extends DH_RoyalMarineCommandos;

defaultproperties
{
    MyName="Light Machine-Gunner"
    AltName="Light Machine-Gunner"
    Article="a "
    PluralName="Light Machine-Gunners"
    bIsGunner=true
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_BrenWeapon')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_ColtM1911Weapon')
    Headgear(0)=class'DH_BritishPlayers.DH_BritishTurtleHelmet'
    Headgear(1)=class'DH_BritishPlayers.DH_BritishTurtleHelmetNet'
    Headgear(2)=class'DH_BritishPlayers.DH_BritishRMCommandoBeret'
    Limit=3
}
