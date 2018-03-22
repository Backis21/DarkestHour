//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_JacksonCannon_Early extends DH_JacksonCannon;

defaultproperties
{
    Skins(3)=Texture'DH_VehiclesGE_tex2.ext_vehicles.Alpha' // hides the muzzle brake
    ProjectileClass=class'DH_Vehicles.DH_JacksonCannonShell_Early'
    PrimaryProjectileClass=class'DH_Vehicles.DH_JacksonCannonShell_Early'
    SecondaryProjectileClass=class'DH_Vehicles.DH_JacksonCannonShellAP'
    ProjectileDescriptions(1)="AP"
    InitialPrimaryAmmo=25
    InitialSecondaryAmmo=12
    MaxPrimaryAmmo=25
    MaxSecondaryAmmo=13
    WeaponFireOffset=16.5
}
