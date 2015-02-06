//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_PanzerIIILCannonShellAPCR extends DH_ROTankCannonShellHVAP;

defaultproperties
{
    MechanicalRanges(1)=(Range=100,RangeValue=4.000000)
    MechanicalRanges(2)=(Range=200,RangeValue=10.000000)
    MechanicalRanges(3)=(Range=300,RangeValue=15.000000)
    MechanicalRanges(4)=(Range=400,RangeValue=22.000000)
    MechanicalRanges(5)=(Range=500,RangeValue=31.000000)
    MechanicalRanges(6)=(Range=600,RangeValue=42.000000)
    MechanicalRanges(7)=(Range=700,RangeValue=55.000000)
    MechanicalRanges(8)=(Range=800,RangeValue=76.000000)
    MechanicalRanges(9)=(Range=900,RangeValue=97.000000)
    MechanicalRanges(10)=(Range=1000,RangeValue=130.000000)
    MechanicalRanges(11)=(Range=1100,RangeValue=167.000000)
    MechanicalRanges(12)=(Range=1200,RangeValue=204.000000)
    MechanicalRanges(13)=(Range=1300,RangeValue=249.000000)
    MechanicalRanges(14)=(Range=1400,RangeValue=293.000000)
    MechanicalRanges(15)=(Range=1500,RangeValue=363.000000)
    MechanicalRanges(16)=(Range=1600,RangeValue=432.000000)
    MechanicalRanges(17)=(Range=1700,RangeValue=515.000000)
    MechanicalRanges(18)=(Range=1800,RangeValue=597.000000)
    MechanicalRanges(19)=(Range=1900,RangeValue=685.000000)
    MechanicalRanges(20)=(Range=2000,RangeValue=772.000000)
    bMechanicalAiming=true
    DHPenetrationTable(0)=14.900000
    DHPenetrationTable(1)=13.200000
    DHPenetrationTable(2)=10.800000
    DHPenetrationTable(3)=8.800000
    DHPenetrationTable(4)=7.200000
    DHPenetrationTable(5)=5.900000
    DHPenetrationTable(6)=4.800000
    DHPenetrationTable(7)=4.100000
    DHPenetrationTable(8)=3.200000
    DHPenetrationTable(9)=2.100000
    DHPenetrationTable(10)=1.400000
    ShellDiameter=5.000000
    bIsAlliedShell=false
    TracerEffect=class'DH_Effects.DH_OrangeTankShellTracer'
    ShellImpactDamage=class'DH_Vehicles.DH_PanzerIIILCannonShellDamageAPCR'
    ImpactDamage=325
    BallisticCoefficient=0.950000
    SpeedFudgeScale=0.400000
    Speed=71313.000000
    MaxSpeed=71313.000000
    StaticMesh=StaticMesh'DH_Tracers.shells.German_shell'
    Tag="PzGr.40"
}
