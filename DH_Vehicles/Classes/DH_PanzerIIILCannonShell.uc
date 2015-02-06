//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_PanzerIIILCannonShell extends DH_GermanTankCannonShell;

defaultproperties
{
    MechanicalRanges(1)=(Range=100,RangeValue=8.000000)
    MechanicalRanges(2)=(Range=200,RangeValue=18.000000)
    MechanicalRanges(3)=(Range=300,RangeValue=29.000000)
    MechanicalRanges(4)=(Range=400,RangeValue=36.000000)
    MechanicalRanges(5)=(Range=500,RangeValue=45.000000)
    MechanicalRanges(6)=(Range=600,RangeValue=52.000000)
    MechanicalRanges(7)=(Range=700,RangeValue=65.000000)
    MechanicalRanges(8)=(Range=800,RangeValue=73.000000)
    MechanicalRanges(9)=(Range=900,RangeValue=90.000000)
    MechanicalRanges(10)=(Range=1000,RangeValue=97.000000)
    MechanicalRanges(11)=(Range=1100,RangeValue=115.000000)
    MechanicalRanges(12)=(Range=1200,RangeValue=123.000000)
    MechanicalRanges(13)=(Range=1300,RangeValue=135.000000)
    MechanicalRanges(14)=(Range=1400,RangeValue=150.000000)
    MechanicalRanges(15)=(Range=1500,RangeValue=162.000000)
    MechanicalRanges(16)=(Range=1600,RangeValue=177.000000)
    MechanicalRanges(17)=(Range=1700,RangeValue=194.000000)
    MechanicalRanges(18)=(Range=1800,RangeValue=213.000000)
    MechanicalRanges(19)=(Range=1900,RangeValue=228.000000)
    MechanicalRanges(20)=(Range=2000,RangeValue=248.000000)
    bMechanicalAiming=true
    DHPenetrationTable(0)=9.600000
    DHPenetrationTable(1)=8.900000
    DHPenetrationTable(2)=7.900000
    DHPenetrationTable(3)=7.000000
    DHPenetrationTable(4)=6.200000
    DHPenetrationTable(5)=5.500000
    DHPenetrationTable(6)=4.900000
    DHPenetrationTable(7)=4.200000
    DHPenetrationTable(8)=3.800000
    DHPenetrationTable(9)=3.000000
    DHPenetrationTable(10)=2.300000
    ShellDiameter=5.000000
    TracerEffect=class'DH_Effects.DH_OrangeTankShellTracer'
    ShellImpactDamage=class'DH_Vehicles.DH_PanzerIIILCannonShellDamageAP'
    ImpactDamage=390
    BallisticCoefficient=1.190000
    Speed=50392.000000
    MaxSpeed=50392.000000
    StaticMesh=StaticMesh'WeaponPickupSM.shells.76mm_shell'
    Tag="PzGr.39"
}
