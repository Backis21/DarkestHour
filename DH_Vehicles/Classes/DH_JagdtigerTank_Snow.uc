//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_JagdtigerTank_Snow extends DH_JagdtigerTank;

#exec OBJ LOAD FILE=..\Textures\DH_VehiclesGE_tex3.utx

defaultproperties
{
    Skins(0)=Texture'DH_VehiclesGE_tex3.ext_vehicles.JagdTiger_body_snow'
    Skins(4)=Texture'DH_VehiclesGE_tex3.ext_vehicles.JagdTiger_skirtwinter'
    CannonSkins(0)=Texture'DH_VehiclesGE_tex3.ext_vehicles.JagdTiger_body_snow'
    DestroyedVehicleMesh=StaticMesh'DH_German_vehicles_stc2.Jagdtiger.Jagdtiger_destsnow'
}
