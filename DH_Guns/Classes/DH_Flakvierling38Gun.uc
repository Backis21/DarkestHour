//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_Flakvierling38Gun extends DHATGun;

#exec OBJ LOAD FILE=..\Animations\DH_Flak38_anm.ukx
#exec OBJ LOAD FILE=..\StaticMeshes\DH_Artillery_stc.usx
#exec OBJ LOAD FILE=..\Textures\DH_Artillery_tex.utx

defaultproperties
{
    VehicleNameString="2cm Flakvierling 38 gun"
    PassengerWeapons(0)=(WeaponPawnClass=class'DH_Guns.DH_Flakvierling38CannonPawn',WeaponBone="Turret_placement")
    Mesh=SkeletalMesh'DH_Flak38_anm.flakvierling_base'
    Skins(0)=Texture'DH_Artillery_tex.flakvierling.FlakVeirling38'
    DestroyedVehicleMesh=StaticMesh'DH_Artillery_stc.flakvierling.Flakvierling38_dest'
    VehicleHudImage=Texture'DH_Artillery_tex.ATGun_Hud.flakv38_base'
    VehicleHudTurret=TexRotator'DH_Artillery_tex.ATGun_Hud.flakv38_turret_rot'
    VehicleHudTurretLook=TexRotator'DH_Artillery_tex.ATGun_Hud.flakv38_turret_look'
    ExitPositions(1)=(X=-100.0,Y=40.0,Z=50.0)  // right of seat
    ExitPositions(2)=(X=-100.0,Y=-40.0,Z=50.0) // left
}
