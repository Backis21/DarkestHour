//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2019
//==============================================================================

class DH_MolotovSubProjectile extends DHProjectile;

var     class<Actor>    FlameEffect;
var private Actor       _FlameInstance;

//==============================================================================
// Variables from deprecated ROThrowableExplosiveProjectile:

var     byte            ThrowerTeam;      // the team number of the person that threw this projectile
var     AvoidMarker     Fear;             // scares the bots away from this

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        SetTimer(1.0, true);
    }

    if (Level.NetMode != NM_DedicatedServer)
    {
        _FlameInstance = Spawn(FlameEffect);//,,, Location, rotator(vect(0,0,1)));
        _FlameInstance.SetBase(self);
        _FlameInstance.SetRelativeLocation(vect(0, 0, 0));

        bDynamicLight = true;
    }
    else
    {
        bDynamicLight = false;
    }

    if (InstigatorController != none)
    {
        ThrowerTeam = InstigatorController.GetTeamNum();
    }
}

simulated function Destroyed()
{
    if (Fear != none) Fear.Destroy();
    if (_FlameInstance != none) _FlameInstance.Destroy();

    super.Destroyed();
}

// Modified to handle new collision mesh actor - if we hit a col mesh, we switch hit actor to col mesh's owner & proceed as if we'd hit that actor
// Also to call CheckVehicleOccupantsRadiusDamage() instead of DriverRadiusDamage() on a hit vehicle, to properly handle blast damage to any exposed vehicle occupants
// And to fix problem affecting many vehicles with hull mesh modelled with origin on the ground, where even a slight ground bump could block all blast damage
// Also to update Instigator, so HurtRadius attributes damage to the player's current pawn
function HurtRadius
(
    float damageAmount,
    float damageRadius,
    class<DamageType> damageType,
    float momentum,
    vector hitLocation
)
{
    local Actor         victim, traceActor;
    local DHVehicle     victimVehicle;
    local ROVehicle     lastTouchedVehicle;
    local ROPawn        victimPawn;
    local array<ROPawn> checkedROPawns;
    local bool          bAlreadyChecked;
    local vector        victimLocation, direction, traceHitLocation, traceHitNormal;
    local float         damageScale, distance, damageExposure;
    local int           i;

    // Make sure nothing else runs HurtRadius while we are in the middle of the function
    if (bHurtEntry)
    {
        return;
    }

    UpdateInstigator();

    // Just return if the player switches teams after throwing the explosive - this prevent people TK exploiting by switching teams
    if (InstigatorController == none || InstigatorController.GetTeamNum() != ThrowerTeam || ThrowerTeam == 255)
    {
        return;
    }

    bHurtEntry = true;

    // Find all colliding actors within blast radius, which the blast should damage
    // No longer use VisibleCollidingActors as much slower (FastTrace on every actor found), but we can filter actors & then we do our own, more accurate trace anyway
    foreach CollidingActors(class'Actor', victim, damageRadius, hitLocation)
    {
        if (!victim.bBlockActors || victim.IsA(class'Projectile'.Name)) // ignore other projectiles
        {
            continue;
        }

        // If hit a collision mesh actor, switch to its owner
        if (victim.IsA(class'DHCollisionMeshActor'.Name))
        {
            if (DHCollisionMeshActor(victim).bWontStopBlastDamage)
            {
                continue; // ignore col mesh actor if it is set not to stop blast damage
            }

            victim = victim.Owner;
        }

        // Don't damage this projectile, an actor already damaged by projectile impact (HurtWall), cannon actors, non-authority actors, or fluids
        // We skip damage on cannons because the blast will hit the vehicle base so we don't want to double up on damage to the same vehicle
        if (victim == none ||
            victim == self ||
            victim == HurtWall ||
            victim.IsA(class'DHVehicleCannon'.Name) ||
            victim.Role < ROLE_Authority ||
            victim.IsA(class'FluidSurfaceInfo'.Name))
        {
            continue;
        }

        // Now we need to check whether there's something in the way that could shield this actor from the blast
        // Usually we trace to actor's location, but for a vehicle with a cannon we adjust Z location to give a more consistent, realistic tracing height
        // This is because many vehicles are modelled with their origin on the ground, so even a slight bump in the ground could block all blast damage!
        victimLocation = victim.Location;
        victimVehicle = DHVehicle(victim);

        if (victimVehicle != none &&
            victimVehicle.Cannon != none &&
            victimVehicle.Cannon.AttachmentBone != '')
        {
            victimLocation.Z = victimVehicle.GetBoneCoords(victimVehicle.Cannon.AttachmentBone).Origin.Z;
        }

        // Trace from explosion point to the actor to check whether anything is in the way that could shield it from the blast
        traceActor = Trace(/*out*/ traceHitLocation,
                           /*out*/ traceHitNormal,
                           victimLocation,
                           hitLocation);

        if (DHCollisionMeshActor(traceActor) != none)
        {
            if (DHCollisionMeshActor(traceActor).bWontStopBlastDamage)
            {
                continue;
            }

            traceActor = traceActor.Owner; // as normal, if hit a collision mesh actor then switch to its owner
        }

        // Ignore the actor if the blast is blocked by world geometry, a vehicle, or a turret (but don't let a turret block damage to its own vehicle)
        if (traceActor != none &&
            traceActor != victim &&
            (traceActor.bWorldGeometry ||
             traceActor.IsA(class'ROVehicle'.Name) ||
             (traceActor.IsA(class'DHVehicleCannon'.Name) && victim != traceActor.Base)))
        {
            continue;
        }

        // Check for hit on player pawn
        victimPawn = ROPawn(victim);
        if (victimPawn != none)
        {
            // If we hit a player pawn, make sure we haven't already registered the hit & add pawn to array of already hit/checked pawns
            for(i=0 ; i<checkedROPawns.Length ; ++i)
            {
                if (victimPawn == checkedROPawns[i])
                {
                    bAlreadyChecked = true;
                    break;
                }
            }

            if (bAlreadyChecked)
            {
                bAlreadyChecked = false;
                continue;
            }

            checkedROPawns[checkedROPawns.Length] = victimPawn;

            // If player is partially shielded from the blast, calculate damage reduction scale
            damageExposure = victimPawn.GetExposureTo(hitLocation + 15.0 * -Normal(PhysicsVolume.Gravity));

            if (damageExposure <= 0.0)
            {
                continue;
            }
        }

        // Calculate damage based on distance from explosion
        direction = victimLocation - hitLocation;
        distance = FMax(1.0, VSize(direction));
        direction = direction / distance;
        damageScale = 1.0 - FMax(0.0, (distance - victim.CollisionRadius) / damageRadius);

        if (victimPawn != none)
        {
            damageScale *= damageExposure;
        }

        // Record player responsible for damage caused, & if we're damaging LastTouched actor, reset that to avoid damaging it again at end of function
        if (Instigator == none || Instigator.Controller == none)
        {
            victim.SetDelayedDamageInstigatorController(InstigatorController);
        }

        if (victim == LastTouched)
        {
            LastTouched = none;
        }

        // Damage the actor hit by the blast - if it's a vehicle, check for damage to any exposed occupants
        // Log("damageAmount: "@ damageScale @", damageAmount: "@ damageAmount @", final: "@ (damageScale*damageAmount));
        victim.TakeDamage(damageScale * damageAmount,
                          Instigator,
                          victimLocation - 0.5 * (victim.CollisionHeight + victim.CollisionRadius) * direction,
                          damageScale * momentum * direction,
                          damageType);

        if (ROVehicle(victim) != none && ROVehicle(victim).Health > 0)
        {
            CheckVehicleOccupantsRadiusDamage(ROVehicle(victim),
                                              damageAmount,
                                              damageRadius,
                                              damageType,
                                              momentum,
                                              hitLocation);

            // If vehicle's engine is vulnerable to "grenades", then we can cause some damage to the engine!
            if (victimVehicle.EngineDamageFromGrenadeModifier > 0.0)
            {
                // Cause reduced damage to vehicle's engine
                victimVehicle.DamageEngine(damageScale * damageAmount * victimVehicle.EngineDamageFromGrenadeModifier,
                                           Instigator,
                                           victimLocation - 0.5 * (victim.CollisionHeight + victim.CollisionRadius) * direction,
                                           damageScale * momentum * direction,
                                           damageType);
            }
        }
    }

    // Same (or very similar) process for the last actor this projectile hit (Touched), but only happens if actor wasn't found by the check for CollidingActors
    if (LastTouched != none &&
        LastTouched != self &&
        LastTouched.Role == ROLE_Authority &&
        !LastTouched.IsA(class'FluidSurfaceInfo'.Name))
    {
        direction = LastTouched.Location - hitLocation;
        distance = FMax(1.0, VSize(direction));
        direction = direction / distance;
        damageScale = FMax(LastTouched.CollisionRadius / (LastTouched.CollisionRadius + LastTouched.CollisionHeight),
                           1.0 - FMax(0.0, (distance - LastTouched.CollisionRadius)/damageRadius));

        if (Instigator == none || Instigator.Controller == none)
        {
            LastTouched.SetDelayedDamageInstigatorController(InstigatorController);
        }

        LastTouched.TakeDamage(damageScale * damageAmount,
                               Instigator,
                               LastTouched.Location - 0.5 * (LastTouched.CollisionHeight + LastTouched.CollisionRadius) * direction,
                               damageScale * momentum * direction,
                               damageType);

        lastTouchedVehicle = ROVehicle(LastTouched);
        if (lastTouchedVehicle != none && lastTouchedVehicle.Health > 0)
        {
            CheckVehicleOccupantsRadiusDamage(lastTouchedVehicle,
                                              damageAmount,
                                              damageRadius,
                                              damageType,
                                              momentum,
                                              hitLocation);
        }

        LastTouched = none;
    }

    bHurtEntry = false;
}

// New function to check for possible blast damage to all vehicle occupants that don't have collision of their own & so won't be 'caught' by HurtRadius
function CheckVehicleOccupantsRadiusDamage
(
    ROVehicle vehicle,
    float damageAmount,
    float damageRadius,
    class<DamageType> damageType,
    float momentum,
    vector hitLocation
)
{
    local ROVehicleWeaponPawn weaponPawn;
    local int i, numWeapons;

    if (vehicle.Driver != none &&
        vehicle.DriverPositions[vehicle.DriverPositionIndex].bExposed &&
        !vehicle.Driver.bCollideActors &&
        !vehicle.bRemoteControlled)
    {
        VehicleOccupantBlastDamage(vehicle.Driver, damageAmount, damageRadius, damageType, momentum, hitLocation);
    }

    numWeapons = vehicle.WeaponPawns.Length;
    for(i = 0; i < numWeapons; ++i)
    {
        weaponPawn = ROVehicleWeaponPawn(vehicle.WeaponPawns[i]);
        if (weaponPawn != none &&
            weaponPawn.Driver != none &&
            ((weaponPawn.bMultiPosition && weaponPawn.DriverPositions[weaponPawn.DriverPositionIndex].bExposed) ||
             weaponPawn.bSinglePositionExposed) &&
            !weaponPawn.bCollideActors &&
            !weaponPawn.bRemoteControlled)
        {
            VehicleOccupantBlastDamage(weaponPawn.Driver, damageAmount, damageRadius, damageType, momentum, hitLocation);
        }
    }
}

function VehicleOccupantBlastDamage
(
    Pawn pawn,
    float damageAmount,
    float damageRadius,
    class<DamageType> damageType,
    float momentum,
    vector hitLocation
)
{
    local Actor  traceHitActor;
    local coords headBoneCoords;
    local vector headLocation, traceHitLocation, traceHitNormal, direction;
    local float  dist, damageScale;

    if (pawn != none)
    {
        headBoneCoords = pawn.GetBoneCoords(pawn.HeadBone);
        headLocation = headBoneCoords.Origin + ((pawn.HeadHeight + (0.5 * pawn.HeadRadius)) * pawn.HeadScale * headBoneCoords.XAxis);

        // Trace from the explosion to the top of player pawn's head & if there's a blocking actor in between (probably the vehicle), exit without damaging pawn
        foreach TraceActors(class'Actor', traceHitActor, traceHitLocation, traceHitNormal, headLocation, hitLocation)
        {
            if (traceHitActor.bBlockActors)
                return;
        }

        // Calculate damage based on distance from explosion
        direction = pawn.Location - hitLocation;
        dist = FMax(1.0, VSize(direction));
        direction = direction / dist;
        damageScale = 1.0 - FMax(0.0, (dist - pawn.CollisionRadius)/damageRadius);

        // Damage the vehicle occupant
        if (damageScale > 0.0)
        {
            pawn.SetDelayedDamageInstigatorController(InstigatorController);
            pawn.TakeDamage(damageScale * damageAmount,
                            InstigatorController.Pawn,
                            pawn.Location - (0.5 * (pawn.CollisionHeight + pawn.CollisionRadius)) * direction,
                            damageScale * momentum * direction,
                            damageType);
        }
    }
}

// New function updating Instigator reference to ensure damage is attributed to correct player, as may have switched to different pawn since throwing, e.g. entered vehicle
simulated function UpdateInstigator()
{
    if (InstigatorController != none && InstigatorController.Pawn != none)
    {
        Instigator = InstigatorController.Pawn;
    }
}

simulated function Landed(vector hitNormal)
{
    HitWall(hitNormal, none);
}

simulated function HitWall(vector hitNormal, Actor wall)
{
    local RODestroyableStaticMesh destroMesh;
    local Class<DamageType> nextDamageType;
    local int i, max;
    local float impactSpeed, impactObliquityAngle, obliquityDotProduct;

    destroMesh = RODestroyableStaticMesh(wall);
    impactSpeed = VSize(Velocity);
    obliquityDotProduct = Normal(-Velocity) dot hitNormal;
    impactObliquityAngle = Acos(obliquityDotProduct) * 180.0 / Pi;

    // We hit a destroyable mesh that is so weak it doesn't stop bullets (e.g. glass), so we'll probably break it instead of bouncing off it
    if (destroMesh != none && destroMesh.bWontStopBullets)
    {
        // On a server (single player), we'll simply cause enough damage to break the mesh
        if (Role == ROLE_Authority)
        {
            destroMesh.TakeDamage(destroMesh.Health + 1,
                                  Instigator,
                                  Location,
                                  MomentumTransfer * Normal(Velocity),
                                  class'DHWeaponBashDamageType');

            // But it will only take damage if it's vulnerable to a weapon bash - so check if it's been reduced to zero Health & if so then we'll exit without deflecting
            if (destroMesh.Health<0)
            {
                return;
            }
        }
        // Problem is that a client needs to know right now whether or not the mesh will break, so it can decide whether or not to bounce off
        // So as a workaround we'll loop through the meshes TypesCanDamage array & check if the server's weapon bash DamageType will have broken the mesh
        else
        {
            max = destroMesh.TypesCanDamage.Length;
            for(i = 0; i < max; ++i)
            {
                // The destroyable mesh will be damaged by a weapon bash, so we'll exit without deflecting
                nextDamageType = destroMesh.TypesCanDamage[i];
                if (nextDamageType == class'DHWeaponBashDamageType' ||
                    ClassIsChildOf(class'DHWeaponBashDamageType', nextDamageType))
                {
                    return;
                }
            }
        }
    }
}

// Modified to handle new collision mesh actor - if we hit a CM we switch hit actor to CM's owner & proceed as if we'd hit that actor
simulated singular function Touch(Actor other)
{
    local vector hitLocation, hitNormal;

    // Added splash if projectile hits a fluid surface
    if (FluidSurfaceInfo(other) != none)
    {
        self.Destroy();
    }

    if (other == none || (!other.bProjTarget && !other.bBlockActors))
    {
        return;
    }

    // We use TraceThisActor do a simple line check against the actor we've hit, to get an accurate HitLocation to pass to ProcessTouch()
    // It's more accurate than using our current location as projectile has often travelled further by the time this event gets called
    // But if that trace returns true then it somehow didn't hit the actor, so we fall back to using our current location as the HitLocation
    // Also skip trace & use our location if velocity is zero (touching actor when projectile spawns) or hit a Mover actor (legacy, don't know why)
    if (VSizeSquared(Velocity) == 0 ||
        other.IsA(class'Mover'.Name) ||
        other.TraceThisActor(/*out*/ hitLocation,
                             /*out*/ hitNormal,
                             Location,
                             Location - (2.0 * Velocity),
                             GetCollisionExtent()))
    {
        hitLocation = Location;
    }

    // Special handling for hit on a collision mesh actor - switch hit actor to CM's owner & proceed as if we'd hit that actor
    if (other.IsA(class'DHCollisionMeshActor'.Name))
    {
        if (DHCollisionMeshActor(other).bWontStopThrownProjectile)
        {
            return; // exit, doing nothing, if col mesh actor is set not to stop a thrown projectile, e.g. grenade or satchel
        }

        other = other.Owner;
    }

    // Now call ProcessTouch(), which is the where the class-specific Touch functionality gets handled
    // Record LastTouched to make sure that if HurtRadius gets called to give blast damage, it will always 'find' the hit actor
    LastTouched = other;
    ProcessTouch(other, hitLocation);
    LastTouched = none;
}

simulated function ProcessTouch(Actor other, vector hitLocation)
{
    local vector tempHitLocation, hitNormal;

    if (other == Instigator ||
        other.Base == Instigator ||
        ROBulletWhipAttachment(other) != none)
    {
        return;
    }

    Trace(/*out*/ tempHitLocation,
          /*out*/ hitNormal,
          hitLocation + Normal(Velocity) * 50.0,
          hitLocation - Normal(Velocity) * 50.0,
          true); // get a reliable HitNormal for a deflection

    // call HitWall for all hit actors, so grenades etc bounce off things like turrets or other players
    HitWall(hitNormal, other);
}

function Timer ()
{
    HurtRadius(Damage,
               DamageRadius,
               MyDamageType,
               0,
               Location);
}

// Modified to fix UT2004 bug affecting non-owning net players in any vehicle with bPCRelativeFPRotation (nearly all), often causing effects to be skipped
// Vehicle's rotation was not being factored into calcs using the PlayerController's rotation, which effectively randomised the result of this function
simulated function bool EffectIsRelevant(vector spawnLocation, bool bForceDedicated)
{
    local PlayerController playerController;

    // Only relevant on a dedicated server if the bForceDedicated option has been passed
    if (Level.NetMode == NM_DedicatedServer)
    {
        return bForceDedicated;
    }

    if (Role < ROLE_Authority)
    {
        // Always relevant for the owning net player, i.e. the player that fired the projectile
        if (Instigator != none && Instigator.IsHumanControlled())
        {
            return true;
        }

        // Not relevant to other net clients if the projectile has not been drawn on their screen recently (within last 3 seconds)
        if ((Level.TimeSeconds-LastRenderTime) >= 3.0)
        {
            return false;
        }
    }

    playerController = Level.GetLocalPlayerController();

    if (playerController == none || playerController.ViewTarget == none)
    {
        return false;
    }

    // Check to see whether effect would spawn off to the side or behind where player is facing, & if so then only spawn if within quite close distance
    // Using PC's CalcViewRotation, which is the last recorded camera rotation, so a simple way of getting player's non-relative view rotation, even in vehicles
    // (doesn't apply to the player that fired the projectile)
    if (playerController.Pawn != Instigator &&
        vector(playerController.CalcViewRotation) dot (spawnLocation-playerController.ViewTarget.Location) < 0.0)
    {
        return VSizeSquared(playerController.ViewTarget.Location-spawnLocation) < (1600*1600); // 1600 UU or 26.5m (changed to VSizeSquared as more efficient)
    }

    // Effect relevance is based on normal distance check
    return CheckMaxEffectDistance(playerController, spawnLocation);
}

simulated function PhysicsVolumeChange(PhysicsVolume newVolume)
{
    // if thrown projectile hits water
    if (newVolume != none && newVolume.bWaterVolume)
    {
        // fire is out!
        self.Destroy();
    }
}

defaultproperties
{
    bNetTemporary=false
    bBlockHitPointTraces=false
    LifeSpan=30.0

    // damage
    Damage=80.0
    DamageRadius=150.0
    MyDamageType=class'DHBurningDamageType'

    // physics
    Physics=PHYS_Falling
    bCollideWorld=true
    bCollideActors=true
    bBlockActors=false
    CollisionRadius=5.0
    CollisionHeight=0.0
    bBounce=false
    MaxSpeed=1500.0

    // fx
    FlameEffect=class'DH_Effects.DHMolotovCoctailProjectile'

    // sound
    SoundVolume=80;
    SoundRadius=500
    AmbientSound=Sound'DH_MolotovCocktail.burning-loop'//Sound'Amb_Destruction.Fire.Krasnyi_Fire_House02'//Sound'Amb_Destruction.Fire.Kessel_Fire_Small_Barrel'

    // give light
    // LightType=LT_Pulse
    // LightBrightness=3.0
    // LightRadius=70.0
    // LightHue=10
    // LightSaturation=255
}