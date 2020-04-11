//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2019
//==============================================================================

class DHRevolverWeapon extends DHBoltActionWeapon
    abstract;

defaultproperties
{
    SwayModifyFactor=1.1 // More sway for pistols
    BobModifyFactor=0.2  // Less weapon bob for pistols

    bCanAttachOnBack=false
    InventoryGroup=3
    Priority=5
    FreeAimRotationSpeed=8.0
    AIRating=0.35
    CurrentRating=0.35
    bSniping=false
    bUsesIronsightFOV=false

    bShouldSkipBolt=true
    bCanUseUnfiredRounds=false
}