//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_WHGunner_SnowTwo extends DH_HeerSnowTwo;

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
    Limit=2
}
