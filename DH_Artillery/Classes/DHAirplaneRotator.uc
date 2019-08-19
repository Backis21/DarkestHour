 //==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2019
//==============================================================================

class DHAirplaneRotator extends Actor;

defaultproperties
{
    DrawType=DT_Mesh
    Mesh=Mesh'DH_Airplanes_anm.bf109g'
    bRotateToDesired=true
    Physics=PHYS_Rotating
    //RotationRate=(Pitch=0,Yaw=0,Roll=-50000)

    bFixedRotationDir=false
    RotationRate=(Pitch=30000,Yaw=30000,Roll=30000)
    //DesiredRotation=(Roll=30000)

    bReplicateMovement=true
    bNetInitialRotation=true
    bAlwaysRelevant=true
    bCollideWorld=false
    RemoteRole=ROLE_SimulatedProxy
}
