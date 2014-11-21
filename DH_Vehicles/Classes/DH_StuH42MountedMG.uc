//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_StuH42MountedMG extends ROVehicleWeapon;


var()   sound ReloadSound; // sound of this MG reloading
var     bool  bReloading;  // This MG is currently reloading
var     int   NumMags;     // Number of mags carried for this MG;

// Stuff for fire effects - Ch!cKeN
var()   name                                    FireAttachBone;
var()   vector                                  FireEffectOffset;
var     class<VehicleDamagedEffect>             FireEffectClass;
var     VehicleDamagedEffect                    HullMGFireEffect;
var     bool                                    bOnFire;   // Set by Treadcraft base to notify when to start fire effects
var     float                                   BurnTime;

var     class<DamageType>   VehicleBurningDamType;
var     float               PlayerFireDamagePerSec;

replication
{
    reliable if (bNetDirty && bNetOwner && Role == ROLE_Authority)
        bReloading, NumMags;

    reliable if (bNetDirty && Role == ROLE_Authority)
        bOnFire;
}

static function StaticPrecache(LevelInfo L)
{
   // L.AddPrecacheMaterial(Material'VMparticleTextures.TankFiringP.CloudParticleOrangeBMPtex');
}

simulated function UpdatePrecacheMaterials()
{
   // Level.AddPrecacheMaterial(Material'VMparticleTextures.TankFiringP.CloudParticleOrangeBMPtex');

    super.UpdatePrecacheMaterials();
}

simulated function Tick(float DeltaTime)
{

    super.Tick(DeltaTime);

    if (bOnFire && HullMGFireEffect == none)
    {
        // Lets randomise the fire start times to desync them with the driver and engine ones
        if (Level.TimeSeconds - BurnTime > 0.2)
        {
            if (FRand() < 0.1)
            {
                HullMGFireEffect = Spawn(FireEffectClass);
                AttachToBone(HullMGFireEffect, FireAttachBone);
                HullMGFireEffect.SetRelativeLocation(FireEffectOffset);
                HullMGFireEffect.UpdateDamagedEffect(true, 0, false, false);
            }
            BurnTime = Level.TimeSeconds;
        }
    }
}


simulated function DestroyEffects()
{
    super.DestroyEffects();

    if (HullMGFireEffect != none)
        HullMGFireEffect.Destroy();
}

// Limit the left and right movement of the turret based on the rotation of the vehicle
simulated function int LimitYaw(int yaw)
{
    local int NewYaw;
    local int VehYaw;

    if (!bLimitYaw)
    {
        return yaw;
    }

    VehYaw = VehicleWeaponPawn(Owner).GetVehicleBase().Rotation.Yaw;

    NewYaw = yaw;

    if (yaw > VehYaw + MaxPositiveYaw)
    {
        NewYaw = VehYaw + MaxPositiveYaw;
    }
    else if (yaw < VehYaw + MaxNegativeYaw)
    {
        NewYaw = VehYaw + MaxNegativeYaw;
    }

    return NewYaw;
}

function byte BestMode()
{
    return 0;
}

// Returns true if this weapon is ready to fire
simulated function bool ReadyToFire(bool bAltFire)
{
    //log("bReloading = "$bReloading);

    if (bReloading)
        return false;

    return super.ReadyToFire(bAltFire);
}

function CeaseFire(Controller C, bool bWasAltFire)
{
    super.CeaseFire(C, bWasAltFire);

    if (!bReloading && !HasAmmo(0))
        HandleReload();
}

function HandleReload()
{
    if (NumMags > 0 && !bReloading)
    {
        bReloading = true;
        NumMags--;
        NetUpdateTime = Level.TimeSeconds - 1;
        SetTimer(GetSoundDuration(ReloadSound), false);
        PlaySound(ReloadSound, SLOT_None,1.5,, 25,, true);
    }
}

simulated function Timer()
{
   if (bReloading)
   {
        if (Role == ROLE_Authority)
        {
            bReloading=false;
            MainAmmoCharge[0] = InitialPrimaryAmmo;
            NetUpdateTime = Level.TimeSeconds - 1;
        }
   }
}

event bool AttemptFire(Controller C, bool bAltFire)
{
    if (Role != ROLE_Authority || bForceCenterAim)
        return false;

    if (FireCountdown <= 0)
    {
        CalcWeaponFire(bAltFire);
        if (bCorrectAim)
            WeaponFireRotation = AdjustAim(bAltFire);

        if (bAltFire)
        {
            if (AltFireSpread > 0)
                WeaponFireRotation = rotator(vector(WeaponFireRotation) + VRand()*FRand()*AltFireSpread);
        }
        else if (Spread > 0)
        {
            WeaponFireRotation = rotator(vector(WeaponFireRotation) + VRand()*FRand()*Spread);
        }

        DualFireOffset *= -1;

        Instigator.MakeNoise(1.0);
        if (bAltFire)
        {
            if (!ConsumeAmmo(2))
            {
                VehicleWeaponPawn(Owner).ClientVehicleCeaseFire(bAltFire);
                return false;
            }
            FireCountdown = AltFireInterval;
            AltFire(C);
        }
        else
        {
            if (bMultipleRoundTypes)
            {
                if (ProjectileClass == PrimaryProjectileClass)
                {
                    if (!ConsumeAmmo(0))
                    {
                        VehicleWeaponPawn(Owner).ClientVehicleCeaseFire(bAltFire);
                        return false;
                    }
                }
                else if (ProjectileClass == SecondaryProjectileClass)
                {
                    if (!ConsumeAmmo(1))
                    {
                        VehicleWeaponPawn(Owner).ClientVehicleCeaseFire(bAltFire);
                        return false;
                    }
                }
            }
            else if (!ConsumeAmmo(0))
            {
                VehicleWeaponPawn(Owner).ClientVehicleCeaseFire(bAltFire);
                HandleReload();
                return false;
            }

            FireCountdown = FireInterval;
            Fire(C);
        }
        AimLockReleaseTime = Level.TimeSeconds + FireCountdown * FireIntervalAimLock;

        return true;
    }

    return false;
}

// Fill the ammo up to the initial ammount
function bool GiveInitialAmmo()
{
    local bool bDidResupply;

    if (NumMags != default.NumMags)
    {
        bDidResupply = true;
    }

    MainAmmoCharge[0] = InitialPrimaryAmmo;
    MainAmmoCharge[1] = InitialSecondaryAmmo;
    AltAmmoCharge = InitialAltAmmo;
    NumMags = default.NumMags;

    return bDidResupply;
}

simulated function int getNumMags()
{
    return NumMags;
}

defaultproperties
{
     ReloadSound=Sound'Vehicle_reloads.Reloads.MG34_ReloadHidden'
     NumMags=8
     FireAttachBone="gunner_int"
     FireEffectOffset=(Z=5.000000)
     FireEffectClass=class'ROEngine.VehicleDamagedEffect'
     VehicleBurningDamType=class'DH_VehicleBurningDamType'
     DummyTracerClass=class'DH_Vehicles.DH_MG34VehicleClientTracer'
     mTracerInterval=0.495867
     bUsesTracers=true
     VehHitpoints(0)=(PointRadius=15.000000,PointScale=1.000000,PointBone="loader_player",PointOffset=(Z=-16.000000))
     bIsMountedTankMG=true
     hudAltAmmoIcon=Texture'InterfaceArt_tex.HUD.mg42_ammo'
     YawBone="Turret"
     PitchBone="Gun"
     PitchUpLimit=10000
     PitchDownLimit=50000
     WeaponFireAttachmentBone="Barrel"
     GunnerAttachmentBone="loader_attachment"
     WeaponFireOffset=3.000000
     RotationsPerSecond=0.050000
     bInstantRotation=true
     bDoOffsetTrace=true
     bAmbientFireSound=true
     bIsRepeatingFF=true
     Spread=0.002000
     FireInterval=0.070580
     AltFireInterval=0.070580
     AmbientEffectEmitterClass=class'ROVehicles.VehicleMGEmitter'
     FireSoundClass=SoundGroup'DH_WeaponSounds.mg34.mg34_fire_loop'
     AmbientSoundScaling=5.000000
     FireEndSound=SoundGroup'DH_WeaponSounds.mg34.mg34_fire_end'
     FireForce="minifireb"
     DamageType=class'ROGame.ROVehMountedMGDamType'
     DamageMin=25
     DamageMax=25
     TraceRange=15000.000000
     ProjectileClass=class'DH_Vehicles.DH_MG34VehicleBullet'
     ShakeRotMag=(X=25.000000,Z=10.000000)
     ShakeRotRate=(X=5000.000000,Y=5000.000000,Z=5000.000000)
     ShakeRotTime=2.000000
     ShakeOffsetMag=(X=0.500000,Z=0.200000)
     ShakeOffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
     ShakeOffsetTime=2.000000
     AIInfo(0)=(bLeadTarget=true,bFireOnRelease=true,aimerror=800.000000,RefireRate=0.070580)
     CustomPitchUpLimit=4500
     CustomPitchDownLimit=63500
     MaxPositiveYaw=5500
     MaxNegativeYaw=-5500
     BeginningIdleAnim="com_idle_close"
     InitialPrimaryAmmo=75
     CullDistance=8000.000000
     Mesh=SkeletalMesh'DH_Stug3G_anm.StuH_mg_remote'
     Skins(0)=Texture'DH_VehiclesGE_tex2.ext_vehicles.Stug3g_body_ext'
     Skins(2)=Texture'Weapons3rd_tex.German.mg34_world'
     bCollideActors=true
     bBlockActors=true
     bProjTarget=true
     bBlockZeroExtentTraces=true
     bBlockNonZeroExtentTraces=true
}
