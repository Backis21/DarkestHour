//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_Flak88Cannon extends DH_ATGunCannon;

defaultproperties
{
    SecondarySpread=0.001250
    ReloadSoundOne=Sound'DH_Vehicle_Reloads.Reloads.reload_01s_01'
    ReloadSoundTwo=Sound'DH_Vehicle_Reloads.Reloads.reload_02s_03'
    ReloadSoundThree=Sound'DH_Vehicle_Reloads.Reloads.reload_01s_04'
    CannonFireSound(0)=SoundGroup'Vehicle_Weapons.Tiger.88mm_fire01'
    CannonFireSound(1)=SoundGroup'Vehicle_Weapons.Tiger.88mm_fire02'
    CannonFireSound(2)=SoundGroup'Vehicle_Weapons.Tiger.88mm_fire03'
    ProjectileDescriptions(0)="APCBC"
    RangeSettings(1)=100
    RangeSettings(2)=200
    RangeSettings(3)=300
    RangeSettings(4)=400
    RangeSettings(5)=500
    RangeSettings(6)=600
    RangeSettings(7)=700
    RangeSettings(8)=800
    RangeSettings(9)=900
    RangeSettings(10)=1000
    RangeSettings(11)=1100
    RangeSettings(12)=1200
    RangeSettings(13)=1300
    RangeSettings(14)=1400
    RangeSettings(15)=1500
    RangeSettings(16)=1600
    RangeSettings(17)=1700
    RangeSettings(18)=1800
    RangeSettings(19)=1900
    RangeSettings(20)=2000
    RangeSettings(21)=2200
    RangeSettings(22)=2400
    RangeSettings(23)=2600
    RangeSettings(24)=2800
    RangeSettings(25)=3000
    VehHitpoints(0)=(PointRadius=9.000000,PointScale=1.000000,PointBone="com_attachment",PointOffset=(X=-15.000000,Z=17.000000))
    VehHitpoints(1)=(PointRadius=16.000000,PointScale=1.000000,PointBone="com_attachment",PointOffset=(X=-15.000000,Z=-5.000000))
    YawBone="Turret"
    PitchBone="Gun"
    PitchUpLimit=15000
    PitchDownLimit=45000
    WeaponFireAttachmentBone="Barrel"
    GunnerAttachmentBone="com_attachment"
    WeaponFireOffset=20.000000
    RotationsPerSecond=0.025000
    FireInterval=4.000000
    EffectEmitterClass=class'ROEffects.TankCannonFireEffect'
    FireSoundVolume=512.000000
    RotateSound=Sound'Vehicle_Weapons.Turret.manual_turret_traverse'
    FireForce="Explosion05"
    ProjectileClass=class'DH_Guns.DH_Flak88CannonShell'
    ShakeRotMag=(Z=110.000000)
    ShakeRotRate=(Z=1100.000000)
    ShakeRotTime=2.000000
    ShakeOffsetMag=(Z=5.000000)
    ShakeOffsetRate=(Z=100.000000)
    ShakeOffsetTime=2.000000
    AIInfo(0)=(bLeadTarget=true,WarnTargetPct=0.750000,RefireRate=0.500000)
    AIInfo(1)=(bLeadTarget=true,WarnTargetPct=0.750000,RefireRate=0.015000)
    CustomPitchUpLimit=15474
    CustomPitchDownLimit=64990
    BeginningIdleAnim="Vt3485_driver_idle_close"
    InitialPrimaryAmmo=50
    InitialSecondaryAmmo=42
    PrimaryProjectileClass=class'DH_Guns.DH_Flak88CannonShell'
    SecondaryProjectileClass=class'DH_Guns.DH_Flak88CannonShellHE'
    Mesh=SkeletalMesh'DH_Flak88_anm.flak88_turret'
    Skins(0)=Texture'MilitaryAxisSMT.Artillery.flak_88'
    Skins(1)=Texture'Weapons1st_tex.Bullets.Bullet_Shell_Rifle'
    SoundVolume=130
    SoundRadius=200.000000
}
