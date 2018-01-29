//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_ShermanTank_British extends DH_ShermanTank;

#exec OBJ LOAD FILE=..\Textures\DH_VehiclesUK_tex.utx

defaultproperties
{
    VehicleNameString="Sherman Mk.II"
    Skins(0)=Texture'DH_VehiclesUK_tex.ext_vehicles.Brit_Sherman_body_ext'
    CannonSkins(0)=Texture'DH_VehiclesUK_tex.ext_vehicles.Brit_Sherman_body_ext'
    DestroyedVehicleMesh=StaticMesh'DH_allies_vehicles_stc.Sherman.Brit_Sherman_Dest'
}
