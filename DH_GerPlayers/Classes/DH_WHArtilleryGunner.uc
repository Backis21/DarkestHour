//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_WHArtilleryGunner extends DH_HeerArtilleryCrew;

function class<ROHeadgear> GetHeadgear()
{
    if (FRand() < 0.2)
    {
        return Headgear[0];
    }
    else
    {
        return Headgear[1];
    }
}

defaultproperties
{
    MyName="Artillery Gunner"
    AltName="Artillerie Sch�tze"
    Article="a "
    PluralName="Artillery Gunners"
    InfoText="Artillerie Sch�tze||The artillery gunner is a specialized role, requiring specialized training. ||Only artillery crew can use artillery"
    MenuImage=Texture'InterfaceArt_tex.SelectMenus.Schutze'
    Models(0)="WHA_1"
    Models(1)="WHA_2"
    Models(2)="WHA_3"
    Models(3)="WHA_4"
    SleeveTexture=Texture'Weapons1st_tex.Arms.german_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_Kar98Weapon',Amount=18,AssociatedAttachment=class'ROInventory.ROKar98AmmoPouch')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_P38Weapon',Amount=1)
    Headgear(0)=class'DH_GerPlayers.DH_HeerHelmetThree'
    Headgear(1)=class'DH_GerPlayers.DH_HeerHelmetTwo'
    bCanBeTankCrew=true
    Limit=5
}
