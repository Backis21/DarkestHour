//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_TT33Fire extends DHPistolFire;

defaultproperties
{
    AmmoClass=class'ROAmmo.TT33Ammo'
    AmmoPerFire=1
    ProjectileClass=class'DH_Weapons.DH_TT33Bullet'
    ProjSpawnOffset=(X=25.0,Y=0.0,Z=0.0)
    FAProjSpawnOffset=(X=-15.0,Y=0.0,Z=0.0)
    SpreadStyle=SS_Random
    Spread=500.0
    ShellIronSightOffset=(X=10.0,Y=0.0,Z=0.0)
    ShellHipOffset=(X=0.0,Y=3.0,Z=0.0)
    bReverseShellSpawnDirection=true
    MaxVerticalRecoilAngle=500
    MaxHorizontalRecoilAngle=60
    bWaitForRelease=true
    FireAnimRate=1.0
    FireRate=0.2
    TweenTime=0.0
    FireAnim="Shoot"
    FireIronAnim="Iron_Shoot"
    FireLastAnim="shoot_empty"
    FireIronLastAnim="iron_shoot_empty"
    FireSounds(0)=Sound'Inf_Weapons.tt33.tt33_fire01'
    FireSounds(1)=Sound'Inf_Weapons.tt33.tt33_fire02'
    FireSounds(2)=Sound'Inf_Weapons.tt33.tt33_fire03'
    FlashEmitterClass=class'ROEffects.MuzzleFlash1stPistol'
    ShellEjectClass=class'ROAmmo.ShellEject1st762x25mm'
    ShellRotOffsetIron=(Pitch=10000,Yaw=0,Roll=0)
    ShellRotOffsetHip=(Pitch=2500,Yaw=4000,Roll=0)
    bSplashDamage=false
    bRecommendSplashDamage=false
    bSplashJump=false
    BotRefireRate=0.5
    WarnTargetPct=0.9
    AimError=800.0
    ShakeOffsetMag=(X=3.0,Y=1.0,Z=3.0)
    ShakeOffsetRate=(X=1000.0,Y=1000.0,Z=1000.0)
    ShakeOffsetTime=1.0
    ShakeRotMag=(X=50.0,Y=50.0,Z=50.0)
    ShakeRotRate=(X=10000.0,Y=10000.0,Z=10000.0)
    ShakeRotTime=1.0
    FireForce="AssaultRifleFire"
}
