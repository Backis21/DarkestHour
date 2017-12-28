//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_ISU152CannonShellHE extends DHCannonShellHE;

defaultproperties
{
    ShellDiameter=15.2
    BallisticCoefficient=5.5
    Speed=36211.0 // 600 m/s
    MaxSpeed=36211.0
    Damage=2000.0
    DamageRadius=3000.0
    MyDamageType=class'DH_Engine.DHShellHE105mmDamageType' // a 152mm shell, but 105mm is close enough (it's a very big shell that will throw stuff around more)
    ImpactDamage=3000
    PenetrationMag=1500.0
    Tag="OF-540"
    StaticMesh=StaticMesh'WeaponPickupSM.shells.122mm_shell'
    BlurEffectScalar=3.0

    DHPenetrationTable(0)=9.0  // 100m
    DHPenetrationTable(1)=8.4  // 250m
    DHPenetrationTable(2)=7.9  // 500m
    DHPenetrationTable(3)=7.4
    DHPenetrationTable(4)=7.0  // 1000m
    DHPenetrationTable(5)=6.6
    DHPenetrationTable(6)=6.2  // 1500m
    DHPenetrationTable(7)=5.8
    DHPenetrationTable(8)=5.2  // 2000m
    DHPenetrationTable(9)=4.6
    DHPenetrationTable(10)=4.0 // 3000m

    TransientSoundRadius=3000.0
    ExplosionSound(0)=SoundGroup'Artillery.explosions.explo01'
    ExplosionSound(1)=SoundGroup'Artillery.explosions.explo02'
    ExplosionSound(2)=SoundGroup'Artillery.explosions.explo03'
    ExplosionSound(3)=SoundGroup'Artillery.explosions.explo04'
    ShellDeflectEffectClass=class'ROEffects.ROArtilleryDirtEmitter'
    ShellHitDirtEffectClass=class'ROEffects.ROArtilleryDirtEmitter'
    ShellHitSnowEffectClass=class'ROEffects.ROArtillerySnowEmitter'
    ShellHitWoodEffectClass=class'ROEffects.ROArtilleryDirtEmitter'
    ShellHitRockEffectClass=class'ROEffects.ROArtilleryDirtEmitter'
    ShellHitWaterEffectClass=class'ROEffects.ROArtilleryWaterEmitter'
    ExplosionDecal=class'ROEffects.ArtilleryMarkDirt'
    ExplosionDecalSnow=class'ROEffects.ArtilleryMarkSnow'

    bOpticalAiming=true
    OpticalRanges(0)=(Range=0,RangeValue=0.411)
    OpticalRanges(1)=(Range=100,RangeValue=0.414)
    OpticalRanges(2)=(Range=200,RangeValue=0.418)
    OpticalRanges(3)=(Range=300,RangeValue=0.4205)
    OpticalRanges(4)=(Range=400,RangeValue=0.423)
    OpticalRanges(5)=(Range=500,RangeValue=0.427)
    OpticalRanges(6)=(Range=600,RangeValue=0.430)
    OpticalRanges(7)=(Range=700,RangeValue=0.434)
    OpticalRanges(8)=(Range=800,RangeValue=0.4375)
    OpticalRanges(9)=(Range=900,RangeValue=0.442)
    OpticalRanges(10)=(Range=1000,RangeValue=0.446)
    OpticalRanges(11)=(Range=1200,RangeValue=0.454)
    OpticalRanges(12)=(Range=1400,RangeValue=0.4635)
    OpticalRanges(13)=(Range=1600,RangeValue=0.4745)
    OpticalRanges(14)=(Range=1800,RangeValue=0.4875)
    OpticalRanges(15)=(Range=2000,RangeValue=0.500)
    OpticalRanges(16)=(Range=2200,RangeValue=0.513)
    OpticalRanges(17)=(Range=2400,RangeValue=0.527)
    OpticalRanges(18)=(Range=2600,RangeValue=0.542)
    OpticalRanges(19)=(Range=2800,RangeValue=0.5578)
    OpticalRanges(20)=(Range=3000,RangeValue=0.5745)
    OpticalRanges(21)=(Range=3200,RangeValue=0.592)
    OpticalRanges(22)=(Range=3400,RangeValue=0.612)
    OpticalRanges(23)=(Range=3600,RangeValue=0.629)
    OpticalRanges(24)=(Range=3800,RangeValue=0.6487)
    OpticalRanges(25)=(Range=4000,RangeValue=0.6675)
    OpticalRanges(26)=(Range=4200,RangeValue=0.6877)
    OpticalRanges(27)=(Range=4400,RangeValue=0.7064)
    OpticalRanges(28)=(Range=4600,RangeValue=0.726)
    OpticalRanges(29)=(Range=4800,RangeValue=0.7454)
    OpticalRanges(30)=(Range=5000,RangeValue=0.7657)
    OpticalRanges(31)=(Range=5200,RangeValue=0.786)
    OpticalRanges(32)=(Range=5400,RangeValue=0.805)
    OpticalRanges(33)=(Range=5600,RangeValue=0.824)
    OpticalRanges(34)=(Range=5800,RangeValue=0.845)

    bMechanicalAiming=true // this cannon doesn't actually have mechanical aiming, but this is a fudge to adjust for sight markings that are 'out'
    MechanicalRanges(1)=(Range=100,RangeValue=-1.0)
    MechanicalRanges(2)=(Range=200,RangeValue=-2.0)
    MechanicalRanges(3)=(Range=300,RangeValue=-3.0)
    MechanicalRanges(4)=(Range=400,RangeValue=-4.0)
    MechanicalRanges(5)=(Range=500,RangeValue=-5.0)
    MechanicalRanges(6)=(Range=600,RangeValue=-6.0)
    MechanicalRanges(7)=(Range=700,RangeValue=-7.0)
    MechanicalRanges(8)=(Range=800,RangeValue=-8.0)
    MechanicalRanges(9)=(Range=900,RangeValue=-9.0)
    MechanicalRanges(10)=(Range=1000,RangeValue=-10.0)
    MechanicalRanges(11)=(Range=1200,RangeValue=-12.0)
    MechanicalRanges(12)=(Range=1400,RangeValue=-14.0)
    MechanicalRanges(13)=(Range=1600,RangeValue=-16.0)
    MechanicalRanges(14)=(Range=1800,RangeValue=-18.0)
    MechanicalRanges(15)=(Range=2000,RangeValue=-20.0)
    MechanicalRanges(16)=(Range=2200,RangeValue=-22.0)
    MechanicalRanges(17)=(Range=2400,RangeValue=-24.0)
    MechanicalRanges(18)=(Range=2600,RangeValue=-26.0)
    MechanicalRanges(19)=(Range=2800,RangeValue=-28.0)
    MechanicalRanges(20)=(Range=3000,RangeValue=-30.0)
    MechanicalRanges(21)=(Range=3200,RangeValue=-32.0)
    MechanicalRanges(22)=(Range=3400,RangeValue=-34.0)
    MechanicalRanges(23)=(Range=3600,RangeValue=-36.0)
    MechanicalRanges(24)=(Range=3800,RangeValue=-38.0)
    MechanicalRanges(25)=(Range=4000,RangeValue=-40.0)
    MechanicalRanges(26)=(Range=4200,RangeValue=-42.0)
    MechanicalRanges(27)=(Range=4400,RangeValue=-44.0)
    MechanicalRanges(28)=(Range=4600,RangeValue=-46.0)
    MechanicalRanges(29)=(Range=4800,RangeValue=-48.0)
    MechanicalRanges(30)=(Range=5000,RangeValue=-50.0)
    MechanicalRanges(31)=(Range=5200,RangeValue=-52.0)
    MechanicalRanges(32)=(Range=5400,RangeValue=-54.0)
    MechanicalRanges(33)=(Range=5600,RangeValue=-56.0)
    MechanicalRanges(34)=(Range=5800,RangeValue=-58.0)
}
