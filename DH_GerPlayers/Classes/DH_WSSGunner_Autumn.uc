//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_WSSGunner_Autumn extends DH_WaffenSSAutumn;

defaultproperties
{
    MyName="Machine-Gunner"
    AltName="Maschinengewehrsch�tze"
    Article="a "
    PluralName="Machine-Gunners"
    bIsGunner=true

    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_MG42Weapon')
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_MG34Weapon')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_P38Weapon')
    SecondaryWeapons(1)=(Item=class'DH_Weapons.DH_P08LugerWeapon')
    Headgear(0)=class'DH_GerPlayers.DH_SSHelmetCover'
    Limit=2
}
