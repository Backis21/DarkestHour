//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DH_Sdkfz2342ArmoredCar extends DH_Sdkfz2341ArmoredCar;

defaultproperties
{
    ReinforcementCost=11
    VehicleNameString="Sd.Kfz.234/2 Armored Car"
    PassengerWeapons(0)=(WeaponPawnClass=class'DH_Vehicles.DH_Sdkfz2342CannonPawn')
    DestroyedVehicleMesh=StaticMesh'DH_German_vehicles_stc3.Puma.Puma_dest'
    VehicleHudTurret=TexRotator'DH_InterfaceArt_tex.Tank_Hud.2342_turret_rot'
    VehicleHudTurretLook=TexRotator'DH_InterfaceArt_tex.Tank_Hud.2342_turret_look'
    SpawnOverlay(0)=Material'DH_InterfaceArt_tex.Vehicles.sdkfz_234_2'
}
