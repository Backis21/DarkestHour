//==============================================================================
// DH_JagdpanzerIVMountedMGPawn
//
// Darkest Hour Source - (c) Darkest Hour Team 2010
// Red Orchestra Source - (c) Tripwire Interactive 2006
//
// Jagdpanzer IV tank destroyer bow MG
//==============================================================================
class DH_JagdpanzerIVMountedMGPawn extends DH_ROMountedTankMGPawn;

defaultproperties
{
     OverlayCenterSize=0.500000
     MGOverlay=Texture'DH_VehicleOptics_tex.Common.MG_sight'
     WeaponFov=72.000000
     GunClass=Class'DH_Vehicles.DH_JagdpanzerIVMountedMG'
     bHasAltFire=false
     CameraBone="mg_yaw"
     bDrawDriverInTP=false
     DrivePos=(Z=130.000000)
     ExitPositions(0)=(X=-45.000000,Y=20.000000,Z=150.000000)
     ExitPositions(1)=(X=-125.000000,Y=20.000000,Z=125.000000)
     EntryRadius=130.000000
     FPCamViewOffset=(Z=3.000000)
     TPCamDistance=300.000000
     TPCamLookat=(X=-25.000000,Z=0.000000)
     TPCamWorldOffset=(Z=120.000000)
     VehiclePositionString="in a Jagdpanzer IV Mounted MG"
     VehicleNameString="Jagdpanzer IV Mounted MG"
     PitchUpLimit=2730
     PitchDownLimit=64000
}
