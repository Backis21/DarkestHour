//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2020
//==============================================================================

class DHMortarVehicleWeaponPawn extends DHVehicleWeaponPawn
    abstract
    dependson(DHPlayer);

struct DigitSet
{
    var material    DigitTexture;
    var IntBox      TextureCoords[11];
};

// Deploying, aiming & firing
var     class<DHMortarWeapon>   WeaponClass;  // the weapon class for the carried mortar inventory item
var     float       UndeployingDuration;      // needs literal as server doesn't have HUDOverlay actor & so can't use GetAnimDuration on it
var     bool        bTraversing;              // player is currently adjusting traverse aim
var     float       ElevationAdjustmentDelay; // seconds between individual elevation adjustments
var     float       LastElevationTime;        // records last time elevation was adjusted, so ElevationAdjustmentDelay can be applied
var     bool        bPendingFire;             // player has fired & mortar is about to fire

// Operator ('Driver') animations
const   IdleAnimIndex = 0;
const   FiringAnimIndex = 1;
const   UnflinchAnimIndex = 2;

var     name        DriverFiringAnim;         // anim for player operator when firing
var     name        DriverUnflinchAnim;       // anim for operator when returning to normal pose after flinching when firing
var     byte        CurrentAnimationIndex;    // index for current mortar & operator anims (set by owning client & replicated to server, which replicates to other clients)
var     byte        OldAnimationIndex;        // clientside record of last CurrentAnimationIndex, so net client can tell when server has replicated a new anim

// 1st person HUD overlay animations
var     name        OverlayIdleAnim;
var     name        OverlayFiringAnim;
var     name        OverlayKnobRaisingAnim;
var     name        OverlayKnobLoweringAnim;
var     name        OverlayKnobIdleAnim;
var     name        OverlayKnobTurnLeftAnim;
var     name        OverlayKnobTurnRightAnim;
var     name        OverlayUndeployingAnim;
var     float       OverlayKnobLoweringAnimRate;
var     float       OverlayKnobRaisingAnimRate;
var     float       OverlayKnobTurnAnimRate;

// HUD
var     texture     HUDArcTexture;           // the elevation display
var     TexRotator  HUDArrowTexture;         // indicator icon for current elevation
var     texture     HUDHighExplosiveTexture; // ammo icon for HE rounds
var     texture     HUDSmokeTexture;         // ammo icon for smoke rounds
var     DigitSet    Digits;                  // numerals for showing ammo count

// Fire adjustment info
var     class<DHMapMarker>    TargetMarkerClass;

// mortar periscope & range table handling
var     int         PeriscopeIndex;
var     int         ShooterIndex;

replication
{
    // Variables the server will replicate to all clients except the one that owns this actor
    reliable if (bNetDirty && !bNetOwner && Role == ROLE_Authority)
        CurrentAnimationIndex;

    // Functions a client can call on the server
    reliable if (Role < ROLE_Authority)
        ServerSetCurrentAnimationIndex, ServerUndeploying;
}

///////////////////////////////////////////////////////////////////////////////////////
//  *****************************  KEY ENGINE EVENTS  *****************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to play animations on the mortar & operator, when a new value of CurrentAnimationIndex is received by net client
simulated function PostNetReceive()
{
    super.PostNetReceive();

    // Need to play animations on the mortar & operator
    if (CurrentAnimationIndex != OldAnimationIndex)
    {
        OldAnimationIndex = CurrentAnimationIndex;
        PlayThirdPersonAnimations();
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  VIEW/DISPLAY  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

simulated function SpecialCalcFirstPersonView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local coords  CameraCoords;
    local rotator WeaponAimRot;

    ViewActor = self;

    if (Gun != none)
    {
        CameraCoords = Gun.GetBoneCoords(CameraBone);

        // Get camera location & adjust for any offset positioning
        CameraLocation = CameraCoords.Origin;

        if (FPCamPos != vect(0.0, 0.0, 0.0))
        {
            WeaponAimRot = Gun.CurrentAim;
            WeaponAimRot.Yaw = -WeaponAimRot.Yaw; // all the yaw/traverse for mortars has to be reversed (screwed up mesh rigging)
            WeaponAimRot = rotator(vector(WeaponAimRot) >> Gun.Rotation);
            WeaponAimRot.Roll = Gun.Rotation.Roll;
            CameraLocation += (FPCamPos >> WeaponAimRot);
        }

        // Set camera rotation
        CameraRotation = rotator(CameraCoords.XAxis);
        CameraRotation.Roll = 0; // make the mortar view have no roll

        // Finalise the camera with any shake
        if (PC != none)
        {
            CameraLocation += (PC.ShakeOffset >> PC.Rotation);
            CameraRotation = Normalize(CameraRotation + PC.ShakeRot);
        }
    }
}


simulated function string GetDeflectionAdjustmentString(DHPlayer PC)
{
    local int Deflection;
    local string DeflectionSign;
    local vector WeaponLocation, Target;
    local rotator WeaponRotation;
    local DHGameReplicationInfo.MapMarker TargetMarker;

    if (PC == none)
    {
        return "";
    }

    TargetMarker = PC.FindPersonalMarker(TargetMarkerClass);

    if (TargetMarker.MapMarkerClass == none)
    {
        return "";
    }

    WeaponLocation.X = VehWep.Location.X;
    WeaponLocation.Y = VehWep.Location.Y;

    WeaponRotation = Gun.CurrentAim;
    WeaponRotation.Yaw = -WeaponRotation.Yaw; // reversed due to messed up rigging
    WeaponRotation = rotator(vector(WeaponRotation) >> Gun.Rotation);
    WeaponRotation.Roll = 0;
    WeaponRotation.Pitch = 0;

    Target = TargetMarker.WorldLocation - WeaponLocation;
    Deflection = -class'DHUnits'.static.RadiansToMilliradians(class'UVector'.static.SignedAngle(Target, vector(WeaponRotation), vect(0, 0, 1)));

    if (Abs(Deflection) > 500)
    {
        return "";
    }

    if (Deflection > 0)
    {
        DeflectionSign = "+";
    }

    return DeflectionSign $ string(Deflection);
}

exec function CalibrateFire(int MilsMin, int MilsMax)
{
    local int Mils;
    local DHBallisticProjectile BP;

    if (Level.NetMode == NM_Standalone)
    {
        for (Mils = MilsMin; Mils < MilsMax; Mils += 10)
        {
            VehWep.CurrentAim.Pitch = class'UUnits'.static.MilsToUnreal(Mils);
            VehWep.CurrentAim.Yaw = 0;

            VehWep.CalcWeaponFire(false);
            BP = DHBallisticProjectile(VehWep.SpawnProjectile(VehWep.ProjectileClass, false));

            if (BP != none)
            {
                BP.bIsCalibrating = true;
                BP.LifeStart = Level.TimeSeconds;
                BP.DebugMils = Mils;
                BP.StartLocation = BP.Location;
            }
        }
    }
}

simulated function array<DHArtillerySpottingScope.STargetInfo> PrepareTargetInfo(array<DHGameReplicationInfo.MapMarker> MapMarkers, int YawScaleStep)
{
    local vector                                        WeaponLocation, Delta;
    local rotator                                       WeaponRotation;
    local int                                           Distance, Deflection, i;
    local array<DHArtillerySpottingScope.STargetInfo>   Targets;
    local DHArtillerySpottingScope.STargetInfo          TargetInfo;
    local string                                        SquadName;
    local DHGameReplicationInfo.MapMarker               MapMarker;
    local DHPlayer                                      Player;
    local PlayerController                              PC;

    PC = PlayerController(Controller);
    Player = DHPlayer(PC);

    if(PC == none || Player == none)
    return Targets;

    WeaponLocation = VehWep.Location;
    WeaponLocation.Z = 0.0;

    WeaponRotation.Yaw = VehWep.Rotation.Yaw;
    WeaponRotation.Roll = 0;
    WeaponRotation.Pitch = 0;

    // Prepare target information for each marker
    for(i = 0; i < MapMarkers.Length; i++)
    {
        MapMarker = MapMarkers[i];
        Delta = MapMarker.WorldLocation - WeaponLocation;
        Delta.Z = 0;
        
        Deflection = class'DHUnits'.static.RadiansToMilliradians(class'UVector'.static.SignedAngle(Delta, vector(WeaponRotation), vect(0, 0, 1)));
        SquadName = Player.SquadReplicationInfo.GetSquadName(GetTeamNum(), MapMarker.SquadIndex);
        Distance = int(class'DHUnits'.static.UnrealToMeters(VSize(Delta)));

        TargetInfo.Distance       = Distance;
        TargetInfo.SquadName      = SquadName;
        TargetInfo.YawCorrection  = Deflection / YawScaleStep;
        TargetInfo.Type           = MapMarker.MapMarkerClass;
        Targets[Targets.Length] = TargetInfo;
    }
    return Targets;
}

// Modified to draw the mortar 1st person overlay & HUD information, including elevation, traverse & ammo
// Also to fix bug where HUDOverlay would be destroyed if function called before net client received Controller reference through replication
simulated function DrawHUD(Canvas C)
{
    local PlayerController                              PC;
    local vector                                        Loc;
    local float                                         HUDScale, Elevation;
    local int                                           SizeX, SizeY, RoundIndex, Traverse;
    local byte                                          Quotient, Remainder;
    local string                                        TraverseString;
    local array<DHGameReplicationInfo.MapMarker>        TargetMapMarkers;
    local array<DHArtillerySpottingScope.STargetInfo>   Targets;
    local DHPlayer                                      Player;

    PC = PlayerController(Controller);
    Player = DHPlayer(PC);

    if (PC != none && !PC.bBehindView && HUDOverlay != none && !Level.IsSoftwareRendering() && DHMortarVehicleWeapon(VehWep) != none)
    {
        // Draw HUDOverlay
        HUDOverlay.SetLocation(PC.CalcViewLocation + (HUDOverlayOffset >> PC.CalcViewRotation));
        HUDOverlay.SetRotation(PC.CalcViewRotation);

        if (PC.myHUD == none || PC.myHUD.bHideHUD)
        {
            return;
        }

        // Set drawing font & scale
        C.Font = class'DHHud'.static.GetSmallerMenuFont(C);
        HUDScale = C.SizeY / 1280.0;

        // Get elevation & traverse
        Elevation = DHMortarVehicleWeapon(VehWep).Elevation;

        // without multiplying yaw by (-1) below the yaw readout is reversed
        Traverse = (-1) * class'DHUnits'.static.UnrealToMilliradians(GetGunYaw());
        TraverseString = "T: ";

        if (Traverse > 0) // add a + at the beginning to explicitly state a positive rotation
        {
            TraverseString $= "+";
        }

        TraverseString $= string(Traverse) @ class'GameInfo'.static.MakeColorCode(class'UColor'.default.Gray) $ GetDeflectionAdjustmentString(DHPlayer(PC));

        if(DriverPositionIndex == ShooterIndex)
        {
            // Draw mortar
            C.DrawActor(HUDOverlay, false, true, HUDOverlayFOV);

            // Draw current round type icon
            RoundIndex = VehWep.GetAmmoIndex();

            if (VehWep.HasAmmo(RoundIndex))
            {
                C.SetDrawColor(255, 255, 255, 255);
            }
            else
            {
                C.SetDrawColor(128, 128, 128, 255);
            }

            C.SetPos(HUDScale * 256.0, C.SizeY - HUDScale * 256.0);

            if (RoundIndex == 0)
            {
                C.DrawTile(HUDHighExplosiveTexture, 128.0 * HUDScale, 256.0 * HUDScale, 0.0, 0.0, 128.0, 256.0);
            }
            else
            {
                C.DrawTile(HUDSmokeTexture, 128.0 * HUDScale, 256.0 * HUDScale, 0.0, 0.0, 128.0, 256.0);
            }

            // Draw current round type quantity
            C.SetPos(384.0 * HUDScale, C.SizeY - (160.0 * HUDScale));

            if (VehWep.MainAmmoCharge[RoundIndex] < 10)
            {
                Quotient = VehWep.MainAmmoCharge[RoundIndex];

                SizeX = Digits.TextureCoords[Quotient].X2 - Digits.TextureCoords[Quotient].X1;
                SizeY = Digits.TextureCoords[Quotient].Y2 - Digits.TextureCoords[Quotient].Y1;

                C.DrawTile(Digits.DigitTexture, 40.0 * HUDScale, 64.0 * HUDScale, Digits.TextureCoords[VehWep.MainAmmoCharge[RoundIndex]].X1,
                    Digits.TextureCoords[VehWep.MainAmmoCharge[RoundIndex]].Y1, SizeX, SizeY);
            }
            else
            {
                Quotient = VehWep.MainAmmoCharge[RoundIndex] / 10;
                Remainder = VehWep.MainAmmoCharge[RoundIndex] % 10;

                SizeX = Digits.TextureCoords[Quotient].X2 - Digits.TextureCoords[Quotient].X1;
                SizeY = Digits.TextureCoords[Quotient].Y2 - Digits.TextureCoords[Quotient].Y1;

                C.DrawTile(Digits.DigitTexture, 40.0 * HUDScale, 64.0 * HUDScale, Digits.TextureCoords[Quotient].X1, Digits.TextureCoords[Quotient].Y1, SizeX, SizeY);

                SizeX = Digits.TextureCoords[Remainder].X2 - Digits.TextureCoords[Remainder].X1;
                SizeY = Digits.TextureCoords[Remainder].Y2 - Digits.TextureCoords[Remainder].Y1;

                C.DrawTile(Digits.DigitTexture, 40.0 * HUDScale, 64.0 * HUDScale, Digits.TextureCoords[Remainder].X1, Digits.TextureCoords[Remainder].Y1, SizeX, SizeY);
            }

            // Draw current round type name
            C.SetDrawColor(255, 255, 255, 255);
            C.SetPos(HUDScale * 8.0, C.SizeY - (HUDScale * 96.0));
            C.DrawText(VehWep.ProjectileClass.default.Tag);

            // Draw the elevation indicator icon
            C.SetPos(0.0, C.SizeY - (256.0 * HUDScale));
            C.DrawTile(HUDArcTexture, 256.0 * HUDScale, 256.0 * HUDScale, 0.0, 0.0, 512.0, 512.0);

            HUDArrowTexture.Rotation.Yaw = class'UUnits'.static.DegreesToUnreal(Elevation + 180.0);
            Loc.X = Cos(class'UUnits'.static.DegreesToRadians(Elevation)) * 256.0;
            Loc.Y = Sin(class'UUnits'.static.DegreesToRadians(Elevation)) * 256.0;
            C.SetPos(HUDScale * (Loc.X - 32.0), C.SizeY - (HUDScale * (Loc.Y + 32.0)));
            C.DrawTile(HUDArrowTexture, 64.0 * HUDScale, 64.0 * HUDScale, 0.0, 0.0, 128.0, 128.0);

            // Draw elevation & traverse text
            C.SetDrawColor(255, 255, 255, 255);
            C.SetPos(HUDScale * 8.0, C.SizeY - (HUDScale * 32.0));
            C.DrawText("E:" @ string(Elevation));

            C.SetDrawColor(255, 255, 255, 255);
            C.SetPos(HUDScale * 8.0, C.SizeY - (HUDScale * 64.0));
            C.DrawText(TraverseString);
        }
        else {
            TargetMapMarkers = Player.GetArtilleryMapMarkers();
            Targets = PrepareTargetInfo(TargetMapMarkers, ArtillerySpottingScope.default.YawScaleStep);
            ArtillerySpottingScope.static.DrawSpottingScopeOverlay(C);
            ArtillerySpottingScope.static.DrawRangeTable(C);
            ArtillerySpottingScope.static.DrawPitch(C,
                GetGunPitch(), 
                GetGunPitchMin(),
                GetGunPitchMax());
            ArtillerySpottingScope.static.DrawYaw(C,
                // without multiplying yaw by (-1) below the yaw readout is reversed
                class'DHUnits'.static.UnrealToMilliradians((-1)*GetGunYaw()), 
                class'DHUnits'.static.UnrealToMilliradians(GetGunYawMin()),
                class'DHUnits'.static.UnrealToMilliradians(GetGunYawMax()),
                Targets);
        }
    }
}

simulated function int GetGunPitch()
{
    return DHMortarVehicleWeapon(VehWep).Elevation;
}

simulated function int GetGunPitchMin()
{
    return DHMortarVehicleWeapon(VehWep).default.ElevationMinimum;
}

simulated function int GetGunPitchMax()
{
    return DHMortarVehicleWeapon(VehWep).default.ElevationMaximum;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ************************ MORTAR ENTRY, UNDEPLYING & EXIT *********************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to transfer player's mortar ammo to the mortar when player enters
function KDriverEnter(Pawn P)
{
    DriverEnterTransferAmmunition(P);

    super.KDriverEnter(P);

    GotoState('Idle');
}

// Modified to start in idle state, & to add a range of hints on how to use mortars
simulated function ClientKDriverEnter(PlayerController PC)
{
    local DHPlayer DHP;

    super.ClientKDriverEnter(PC);

    GotoState('Idle');

    DHP = DHPlayer(PC);

    if (DHP != none)
    {
        DHP.QueueHint(7, false);
        DHP.QueueHint(8, false);
        DHP.QueueHint(9, false);
        DHP.QueueHint(10, false);
    }
}

// New replicated client-to-server function called when player undeploys mortar, to send server to state Undeploying
function ServerUndeploying()
{
    if (!IsInState('Undeploying'))
    {
        GotoState('Undeploying');
    }
}

// New function to exit mortar, give player back his mortar inventory item, & maybe destroy mortar vehicle actors (some server modes have to wait until client finishes exiting)
function Undeploy()
{
    local DHMortarWeapon CarriedMortar;
    local Pawn           MortarOperator;

    if (Role == ROLE_Authority && IsInState('Undeploying') && Driver != none)
    {
        MortarOperator = Driver;
        CarriedMortar = Spawn(WeaponClass, MortarOperator);

        if (CarriedMortar != none && global.KDriverLeave(false)) // KDriverLeave normally an empty function in a 'Busy' state, so call the normal, non-state function instead
        {
            CarriedMortar.GiveTo(MortarOperator);

            // Standalone or owning listen server destroys mortar vehicle (& all associated actors) immediately, as ClientKDriverLeave() will already have executed locally
            // Dedicated server or non-owning listen server instead waits until owning net client executes ClientKDriverLeave() & calls ServerDestroyMortar() on server
            if (DHMortarVehicle(VehicleBase) != none)
            {
                DHMortarVehicle(VehicleBase).ServerDestroyMortar();
            }
        }
    }
}

// Modified to transfer ammo from mortar to player, to update player's mortar ammo resupply status, to force player to exit in crouched stance, & to reset to idle state
function bool KDriverLeave(bool bForceLeave)
{
    local Pawn P;

    P = Driver;

    if (super.KDriverLeave(bForceLeave))
    {
        DriverLeaveAmmunitionTransfer(P);

        if (DHPawn(P) != none)
        {
            DHPawn(P).CheckIfMortarCanBeResupplied();
        }

        if (P != none && DHPlayer(P.Controller) != none)
        {
            DHPlayer(P.Controller).ClientToggleDuck(); // TODO: suspect this can be done in ClientKDriverLeave(), removing need for replicated function
        }

        GotoState(''); // reset state for the next person who gets on the mortar

        return true;
    }

    return false;
}

// Modified to match rotation to mortar's aimed direction, so player exits facing the same way as the mortar
// Necessary because while on mortar, his view rotation is locked but his pawn/PC rotation can wander meaninglessly via mouse movement
// Also to destroy the mortar if player just un-deployed it
simulated function ClientKDriverLeave(PlayerController PC)
{
    local rotator NewRotation;

    if (PC != none && Gun != none)
    {
        NewRotation.Yaw = -Gun.CurrentAim.Yaw; // all the yaw/traverse for mortars has to be reversed (screwed up mesh rigging)
        PC.SetRotation(NewRotation);
    }

    super.ClientKDriverLeave(PC);

    // If undeploying, owning net client now tells server to destroy mortar vehicle (& so all associated actors), as we've completed vehicle exit/unpossess process
    if (Role < ROLE_Authority && IsInState('Undeploying') && DHMortarVehicle(VehicleBase) != none)
    {
        DHMortarVehicle(VehicleBase).ServerDestroyMortar();
    }
    // Otherwise we exit state
    else
    {
        GotoState('');
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************* FIRING & AMMO  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New keybound function to toggle the selected ammo type
exec function SwitchFireMode()
{
    Log("DriverPositions.Length=" @ DriverPositions.Length @ ".");
    if (DHMortarVehicleWeapon(Gun) != none && Gun.bMultipleRoundTypes)
    {
        DHMortarVehicleWeapon(Gun).ToggleRoundType();
    }
}

// New function to handle transfer of player's mortar ammo to the mortar when player enters
function DriverEnterTransferAmmunition(Pawn P)
{
    local DHPawn DHP;

    DHP = DHPawn(P);

    if (DHP != none && Gun != none)
    {
        Gun.MainAmmoCharge[0] = Clamp(Gun.MainAmmoCharge[0] + DHP.MortarHEAmmo, 0, GunClass.default.InitialPrimaryAmmo);
        Gun.MainAmmoCharge[1] = Clamp(Gun.MainAmmoCharge[1] + DHP.MortarSmokeAmmo, 0, GunClass.default.InitialSecondaryAmmo);

        DHP.MortarHEAmmo = 0;
        DHP.MortarSmokeAmmo = 0;
    }

    CheckCanBeResupplied();
}

// New function to handle transfer of mortar's ammo to the player when he exits
function DriverLeaveAmmunitionTransfer(Pawn P)
{
    local DHPawn DHP;

    DHP = DHPawn(P);

    if (DHP != none && Gun != none)
    {
        DHP.MortarHEAmmo = Gun.MainAmmoCharge[0];
        DHP.MortarSmokeAmmo = Gun.MainAmmoCharge[1];
        Gun.MainAmmoCharge[0] = 0;
        Gun.MainAmmoCharge[1] = 0;

        if (DHMortarVehicle(VehicleBase) != none)
        {
            DHMortarVehicle(VehicleBase).bCanBeResupplied = true;
        }
    }
}

// New function to flag whether or not mortar has less than full ammo & so can be resupplied
function CheckCanBeResupplied()
{
    if (DHMortarVehicle(VehicleBase) != none)
    {
        DHMortarVehicle(VehicleBase).bCanBeResupplied =
            Gun != none && (Gun.MainAmmoCharge[0] < GunClass.default.InitialPrimaryAmmo || Gun.MainAmmoCharge[1] < GunClass.default.InitialSecondaryAmmo);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************* ACTIVITY STATES *******************************  //
///////////////////////////////////////////////////////////////////////////////////////

simulated state EnteringVehicle
{
    simulated function HandleEnter()
    {
        super.HandleEnter();
        GotoState('Idle');
    }
}


// New state where mortar is not busy doing something, so can be fired, exited, undeployed, etc
simulated state Idle
{
    simulated function BeginState()
    {
        PlayFirstPersonAnimation(OverlayIdleAnim, true);
    }

    simulated function Fire(optional float F)
    {
        if (!ArePlayersWeaponsLocked() && Gun != none && Gun.ReadyToFire(false) && DriverPositionIndex == ShooterIndex)
        {
            GotoState('Firing');
        }
    }

    simulated exec function Deploy()
    {
        GotoState('Undeploying');
    }

    function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange)
    {
        if (YawChange == 0.0 && PitchChange == 0.0)
        {
            global.HandleTurretRotation(DeltaTime, 0.0, 0.0);

            return;
        }
        else if (PitchChange != 0.0 && (Level.TimeSeconds - LastElevationTime) > ElevationAdjustmentDelay && DHMortarVehicleWeapon(Gun) != none)
        {
            LastElevationTime = Level.TimeSeconds;

            if (PitchChange < 0.0)
            {
                DHMortarVehicleWeapon(Gun).Elevate();
            }
            else
            {
                DHMortarVehicleWeapon(Gun).Depress();
            }
        }
        else if (YawChange != 0.0)
        {
            GotoState('KnobRaising');
        }
    }
}

// New base state for various new states where mortar is busy doing something, so several operations are disabled (functions emptied out)
simulated state Busy
{
    function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange) { }
    simulated function Fire(optional float F) { }
    simulated exec function SwitchFireMode() { }
    exec function Deploy() { }
    function bool KDriverLeave(bool bForceLeave) {return false;}
}

// New state where player's hand is raising to traverse adjustment knob
simulated state KnobRaising extends Busy
{
Begin:
    if (HUDOverlay != none)
    {
        PlayFirstPersonAnimation(OverlayKnobRaisingAnim, false, OverlayKnobRaisingAnimRate);
        Sleep(HUDOverlay.GetAnimDuration(OverlayKnobRaisingAnim, OverlayKnobRaisingAnimRate));
    }

    GotoState('KnobRaised');
}

// New state where player's hand is raised on traverse adjustment knob
simulated state KnobRaised
{
    simulated function BeginState()
    {
        PlayFirstPersonAnimation(OverlayKnobIdleAnim, true);
    }

    simulated function Fire(optional float F)
    {
        if (!ArePlayersWeaponsLocked() && Gun != none && Gun.ReadyToFire(false))
        {
            GotoState('KnobRaisedToFire');
        }
    }

    simulated exec function Deploy()
    {
        if (!bTraversing)
        {
            GotoState('KnobRaisedToUndeploy');
        }
    }

    function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange)
    {
        local int CurrentYaw;

        // Adjusting pitch, so we need to move the player's hand down from traverse knob, meaning we exit this state
        if (PitchChange != 0.0)
        {
            GotoState('KnobRaisedToIdle');

            return;
        }

        // If adjusting traverse, make sure we haven't gone beyond the traverse limits (zero YawChange if we have)
        if (YawChange != 0.0 && Gun != none)
        {
            CurrentYaw = Gun.CurrentAim.Yaw;

            if (CurrentYaw > 32768) // convert to +/- yaw format
            {
                CurrentYaw -= 65536;
            }

            CurrentYaw = -CurrentYaw; // yaw/traverse has to be reversed because in the mortar skeletal meshes the root bone rotation is screwed up, so weapon aim ends up reversed!

            // Block traverse if within 10 rotational units of yaw limit - a fudge factor, as sometimes Gun stops slightly short of limit
            if (YawChange > 0.0)
            {
                if (CurrentYaw >= (Gun.MaxPositiveYaw - 10))
                {
                    YawChange = 0.0;
                }
            }
            else if (CurrentYaw <= (Gun.MaxNegativeYaw + 10))
            {
                YawChange = 0.0;
            }
        }

        // Adjusting traverse
        if (YawChange != 0.0)
        {
            bTraversing = true;

            if (YawChange > 0.0)
            {
                PlayFirstPersonAnimation(OverlayKnobTurnRightAnim, true, OverlayKnobTurnAnimRate, 0.125);
            }
            else
            {
                PlayFirstPersonAnimation(OverlayKnobTurnLeftAnim, true, OverlayKnobTurnAnimRate, 0.125);
            }

            global.HandleTurretRotation(DeltaTime, -YawChange, 0); // all the yaw/traverse for mortars has to be reversed (screwed up mesh rigging)

        }
        // We've stopped adjusting traverse
        else if (bTraversing)
        {
            bTraversing = false;

            if (HUDOverlay != none)
            {
                HUDOverlay.StopAnimating(true);
            }

            return;
        }
    }
}

// New state after firing, before returning to Idle state
simulated state FireToIdle extends Busy
{
    simulated function Fire(optional float F)
    {
        if (!ArePlayersWeaponsLocked())
        {
            bPendingFire = true; // allows us to queue up a shot in this stage so we don't have an arbitrary 'waiting time' before we accept input after firing
        }
    }

    simulated function EndState()
    {
        bPendingFire = false;
    }

Begin:
    SetCurrentAnimationIndex(UnflinchAnimIndex);

    if (Driver != none && Driver.HasAnim(DriverUnflinchAnim))
    {
        Sleep(Driver.GetAnimDuration(DriverUnflinchAnim));
    }
    else
    {
        ClientMessage("Missing animation: DriverUnflinchAnim" @ DriverUnflinchAnim);
    }

    if (bPendingFire && Gun != none && Gun.ReadyToFire(false))
    {
        GotoState('Firing');
    }
    else
    {
        GotoState('Idle');
    }
}

// overriding DHVehicle.ViewTransition to enter 'Idle' state instead of ''
simulated state ViewTransition
{
Begin:
    HandleTransition();
    Sleep(ViewTransitionDuration);
    GotoState('Idle');
}


// New state where mortar is being fired
// Fires mortar after firing animation has played (there's a delay firing mortar, as round is dropped down the tube)
simulated state Firing extends Busy
{
    simulated function FireMortar()
    {
        if (Role < ROLE_Authority && DHMortarVehicleWeapon(Gun) != none)
        {
            DHMortarVehicleWeapon(Gun).CheckUpdateFiringSettings();
        }

        super(Vehicle).Fire(); // this triggers the native firing process on the server, but we skip the 'able to fire' checks in the weapon pawn Supers as we've already done them

        if (IsHumanControlled() && Gun != none)
        {
            Gun.ClientStartFire(Controller, false); // from the skipped over VehicleWeaponPawn.Fire() & it calls OwnerEffects() for an owning net client
        }
    }

Begin:
    PlayFirstPersonAnimation(OverlayFiringAnim);
    SetCurrentAnimationIndex(FiringAnimIndex);

    if (HUDOverlay != none && HUDOverlay.HasAnim(OverlayFiringAnim))
    {
        Sleep(HUDOverlay.GetAnimDuration(OverlayFiringAnim));
    }

    FireMortar();
    GotoState('FireToIdle');
}

// New state where player's hand is moving from traverse adjustment knob to fire the mortar
simulated state KnobRaisedToFire extends Busy
{
Begin:
    if (HUDOverlay != none)
    {
        PlayFirstPersonAnimation(OverlayKnobLoweringAnim, false, OverlayKnobLoweringAnimRate);
        Sleep(HUDOverlay.GetAnimDuration(OverlayKnobLoweringAnim, OverlayKnobLoweringAnimRate));
    }

    GotoState('Firing');
}

// New state where player's hand is moving from traverse adjustment knob to undeploy the mortar
simulated state KnobRaisedToUndeploy extends Busy
{
Begin:
    if (HUDOverlay != none)
    {
        PlayFirstPersonAnimation(OverlayKnobLoweringAnim);
        Sleep(HUDOverlay.GetAnimDuration(OverlayKnobLoweringAnim));
    }

    GotoState('Undeploying');
}

// New state where player's hand is moving from traverse adjustment knob to an idle position
simulated state KnobRaisedToIdle extends Busy
{
Begin:
    if (HUDOverlay != none)
    {
        PlayFirstPersonAnimation(OverlayKnobLoweringAnim);
        Sleep(HUDOverlay.GetAnimDuration(OverlayKnobLoweringAnim));
    }

    GotoState('Idle');
}

// New state when player is undeploying the mortar
simulated state Undeploying extends Busy
{
Begin:
    if (IsLocallyControlled()) // single player, or owning net client or listen server
    {
        PlayFirstPersonAnimation(OverlayUndeployingAnim);
        ServerUndeploying();
    }

    if (Role == ROLE_Authority)
    {
        Sleep(UndeployingDuration);
        Undeploy();
    }
}

// From ROTankCannonPawn (re-factored slightly)
// The global function - is overridden in various activity states
function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange)
{
    if (Gun != none && Gun.bUseTankTurretRotation)
    {
        UpdateTurretRotation(DeltaTime, YawChange, PitchChange);

        if (IsHumanControlled())
        {
            PlayerController(Controller).WeaponBufferRotation.Yaw = CustomAim.Yaw;
            PlayerController(Controller).WeaponBufferRotation.Pitch = CustomAim.Pitch;
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *********************************  ANIMATIONS  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New function to set a new CurrentAnimationIndex & play the relevant animations, & for a net client to replicate the CurrentAnimationIndex to the server
simulated function SetCurrentAnimationIndex(byte AnimIndex)
{
    CurrentAnimationIndex = AnimIndex;
    PlayThirdPersonAnimations();

    if (Role < ROLE_Authority)
    {
        ServerSetCurrentAnimationIndex(CurrentAnimationIndex);
    }
}

// New replicated client-to-server function to set CurrentAnimationIndex on server, to be replicated to other net clients, making them play the animations
simulated function ServerSetCurrentAnimationIndex(byte AnimIndex)
{
    CurrentAnimationIndex = AnimIndex;
}

// New function to play current 1st person animations for the mortar & the operator ('Driver')
simulated function PlayThirdPersonAnimations()
{
    switch (CurrentAnimationIndex)
    {
        case IdleAnimIndex:
            if (Gun != none)
            {
                Gun.LoopAnim(Gun.BeginningIdleAnim);
            }

            if (Driver != none)
            {
                Driver.LoopAnim(DriveAnim);
            }

            break;

        case FiringAnimIndex:
            if (DHMortarVehicleWeapon(Gun) != none)
            {
                Gun.PlayAnim(DHMortarVehicleWeapon(Gun).GunFiringAnim);
            }

            if (Driver != none)
            {
                Driver.PlayAnim(DriverFiringAnim);
            }

            break;

        case UnflinchAnimIndex:
            if (Gun != none)
            {
                Gun.LoopAnim(Gun.BeginningIdleAnim);
            }

            if (Driver != none)
            {
                Driver.PlayAnim(DriverUnflinchAnim);
            }
    }
}

// New function to play a 1st person animation on the HUDOverlay
simulated function PlayFirstPersonAnimation(name Anim, optional bool bLoop, optional float Rate, optional float TweenTime)
{
    if (HUDOverlay != none && HUDOverlay.HasAnim(Anim))
    {
        if (Rate == 0.0) // default to 1.0 if no rate was passed
        {
            Rate = 1.0;
        }

        if (bLoop)
        {
            HUDOverlay.LoopAnim(Anim, Rate, TweenTime);
        }
        else
        {
            HUDOverlay.PlayAnim(Anim, Rate, TweenTime);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  MISCELLANEOUS  *******************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add extra material properties
static function StaticPrecache(LevelInfo L)
{
    super.StaticPrecache(L);

    if (default.HUDArcTexture != none)
    {
        L.AddPrecacheMaterial(default.HUDArcTexture);
    }

    if (default.HUDArrowTexture != none)
    {
        L.AddPrecacheMaterial(default.HUDArrowTexture);
    }

    if (default.HUDHighExplosiveTexture != none)
    {
        L.AddPrecacheMaterial(default.HUDHighExplosiveTexture);
    }

    if (default.HUDSmokeTexture != none)
    {
        L.AddPrecacheMaterial(default.HUDSmokeTexture);
    }

    if (default.Digits.DigitTexture != none)
    {
        L.AddPrecacheMaterial(default.Digits.DigitTexture);
    }
}

// Modified to add extra material properties
simulated function UpdatePrecacheMaterials()
{
    super.UpdatePrecacheMaterials();

    Level.AddPrecacheMaterial(HUDArcTexture);
    Level.AddPrecacheMaterial(HUDArrowTexture);
    Level.AddPrecacheMaterial(HUDHighExplosiveTexture);
    Level.AddPrecacheMaterial(HUDSmokeTexture);
    Level.AddPrecacheMaterial(Digits.DigitTexture);
}

// Functions emptied out as not relevant to a mortar:
simulated function SwitchWeapon(byte F);
simulated function bool CanSwitchToVehiclePosition(byte F) { return false; }
simulated exec function ToggleVehicleLock();
function ServerToggleVehicleLock();

defaultproperties
{
    // Mortar operator, aiming & undeploying
    bMultiPosition=true
    ElevationAdjustmentDelay=0.125
    UndeployingDuration=2.0 // just a fallback, in case we forget to set one for the specific mortar
    // View & display
    bDrawMeshInFP=false
    CameraBone="Camera"
    HUDOverlayFOV=90.0
    HUDArrowTexture=TexRotator'DH_Mortars_tex.HUD.ArrowRotator'
    Digits=(DigitTexture=Texture'InterfaceArt_tex.HUD.numbers',TextureCoords[0]=(X1=15,X2=47,Y2=63),TextureCoords[1]=(X1=79,X2=111,Y2=63),TextureCoords[2]=(X1=143,X2=175,Y2=63),TextureCoords[3]=(X1=207,X2=239,Y2=63),TextureCoords[4]=(X1=15,Y1=64,X2=47,Y2=127),TextureCoords[5]=(X1=79,Y1=64,X2=111,Y2=127),TextureCoords[6]=(X1=143,Y1=64,X2=175,Y2=127),TextureCoords[7]=(X1=207,Y1=64,X2=239,Y2=127),TextureCoords[8]=(X1=15,Y1=128,X2=47,Y2=191),TextureCoords[9]=(X1=79,Y1=128,X2=111,Y2=191),TextureCoords[10]=(X1=143,Y1=128,X2=175,Y2=191))
    TPCamDistance=128.0
    TPCamDistRange=(Min=128.0,Max=128.0)
    TPCamLookat=(X=0.0,Y=0.0,Z=16.0)
    TPCamWorldOffset=(X=0.0,Y=0.0,Z=0.0)

    // Animations
    OverlayIdleAnim="deploy_idle"
    OverlayKnobRaisingAnim="knob_raise"
    OverlayKnobLoweringAnim="knob_lower"
    OverlayKnobTurnLeftAnim="traverse_left"
    OverlayKnobTurnRightAnim="traverse_right"
    OverlayFiringAnim="Fire"
    OverlayUndeployingAnim="undeploy"
    OverlayKnobLoweringAnimRate=1.25
    OverlayKnobRaisingAnimRate=1.25
    OverlayKnobTurnAnimRate=1.25

    // Fire adjustment info
    TargetMarkerClass=class'DHMapMarker_Ruler'
    ShooterIndex = 0;
    PeriscopeIndex = 1;
    OverlayCorrectionY = -60.0;
}
