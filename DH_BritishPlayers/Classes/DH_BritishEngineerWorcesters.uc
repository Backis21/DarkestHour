//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_BritishEngineerWorcesters extends DH_Worcesters;

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
    {
        return Headgear[0];
    }
}

defaultproperties
{
    MyName="Combat Engineer"
    AltName="Combat Engineer"
    Article="a "
    PluralName="Combat Engineers"
    InfoText="The combat engineer is tasked with destroying front-line enemy obstacles and fortifications.  Geared for close quarters combat, the combat engineer is generally equipped with sub machine-guns and grenades.  For instances where enemy fortifications or obstacles are exposed to enemy fire, he is equipped with concealment smoke so he may get close enough to destroy the target."
    MenuImage=Texture'DHBritishCharactersTex.Icons.Brit_Eng'
    Models(0)="Wor_1"
    Models(1)="Wor_2"
    Models(2)="Wor_3"
    Models(3)="Wor_4"
    Models(4)="Wor_5"
    Models(5)="Wor_6"
    SleeveTexture=Texture'DHBritishCharactersTex.Sleeves.brit_sleeves'
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_StenMkIIWeapon',Amount=6)
    Grenades(0)=(Item=class'DH_Weapons.DH_M1GrenadeWeapon',Amount=2)
    Grenades(1)=(Item=class'DH_Equipment.DH_USSmokeGrenadeWeapon',Amount=1)
    GivenItems(0)="DH_Weapons.DH_SatchelCharge10lb10sWeapon"
    Headgear(0)=class'DH_BritishPlayers.DH_BritishTurtleHelmet'
    Headgear(1)=class'DH_BritishPlayers.DH_BritishTurtleHelmetNet'
    Headgear(2)=class'DH_BritishPlayers.DH_BritishTommyHelmet'
    PrimaryWeaponType=WT_SMG
    Limit=1
}
