//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DHSpawnPointBase extends Actor
    abstract;

enum ESpawnPointBlockReason
{
    SPBR_None,
    SPBR_EnemiesNearby,
    SPBR_InObjective,
    SPBR_Full,
    SPBR_Constructing
};

var bool bCombatSpawn;
var int SpawnPointIndex;
var private int TeamIndex;
var ESpawnPointBlockReason BlockReason;
var private bool bIsActive;

// Parameters for spawning in a radius (NOTE: currently only works for infantry!)
var vector  SpawnLocationOffset;
var float   SpawnRadius;
var int     SpawnRadiusSegmentCount;

var protected DHGameReplicationInfo GRI;

// The amount of time, in seconds, that a player will be invulnerable after
// spawning on this spawn point.
var float SpawnProtectionTime;

// The amount of time, in seconds, that a player will be considered a spawn kill
// after spawning on this spawn point.
var float SpawnKillProtectionTime;

replication
{
    reliable if (Role == ROLE_Authority)
        SpawnPointIndex, TeamIndex, BlockReason, bIsActive;
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        // Add this spawn point to the GRI's list of spawn points.
        GRI = DHGameReplicationInfo(Level.Game.GameReplicationInfo);

        SpawnPointIndex = GRI.AddSpawnPoint(self);

        if (SpawnPointIndex == -1)
        {
            Error("Failed to add" @ self @ "to spawn point list!");
        }
    }
}

// Override to provide the business logic that does the spawning.
function bool PerformSpawn(DHPlayer PC);

// Called when a pawn is spawn killed from this spawn point. Override in child classes.
function OnSpawnKill(Pawn VictimPawn, Controller KillerController);

// Override to specify which vehicles can spawn at this spawn point.
simulated function bool CanSpawnVehicle(DHGameReplicationInfo GRI, int VehiclePoolIndex, optional bool bSkipTimeCheck);

// Override to limit certain roles from using this spawn point.
simulated function bool CanSpawnRole(DHRoleInfo RI)
{
    return RI != none;
}

// Override to specify a different spawn pose, otherwise it just uses the spawn point's pose.
function bool GetSpawnPosition(out vector SpawnLocation, out rotator SpawnRotation, int VehiclePoolIndex)
{
    local int i, j, k;
    local DHPawnCollisionTest CT;
    local vector L;
    local float Angle, AngleInterval;

    // TODO: The spawn radius only works for infantry spawns; in future it would
    // be handy to use a radius for vehicle spawns. Unfortunately this is less
    // reliable since the vehicle radii would ahve to be much considerably larger
    // due to their larger and varied sizes.
    if (VehiclePoolIndex == -1 && SpawnRadius != 0.0)
    {
        // Calculate the arclength of the
        AngleInterval = (Pi * 2) / SpawnRadiusSegmentCount;
        j = Rand(SpawnRadiusSegmentCount);

        for (i = 0; i < SpawnRadiusSegmentCount; ++i)
        {
            k = (i + j) % SpawnRadiusSegmentCount;
            Angle = AngleInterval * k;

            L = Location;
            L.X += Cos(Angle) * SpawnRadius;
            L.Y += Sin(Angle) * SpawnRadius;
            L.Z += 10.0 + class'DHPawn'.default.CollisionHeight / 2;

            CT = Spawn(class'DHPawnCollisionTest',,, L);

            if (CT != none)
            {
                break;
            }
        }

        if (CT != none)
        {
            SpawnLocation = L + SpawnLocationOffset;
            SpawnRotation = Rotation;
            CT.Destroy();
            return true;
        }
    }

    SpawnLocation = Location + SpawnLocationOffset;
    SpawnRotation = Rotation;

    return true;
}

// Returns true if the spawn point is "visible" to a player with the arguments
// provided.
simulated function bool IsVisibleTo(int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex)
{
    if (self.TeamIndex != TeamIndex || !bIsActive)
    {
        return false;
    }

    return true;
}

// A blocked spawn point is an active spawn point that, for whatever reason,
// is not currently available to be spawned on.
simulated function bool IsBlocked()
{
    return BlockReason != SPBR_None;
}

// Returns true if the given arguments are satisfactory for spawning on this
// spawn point.
simulated function bool CanSpawnWithParameters(DHGameReplicationInfo GRI, int TeamIndex, int RoleIndex, int SquadIndex, int VehiclePoolIndex, optional bool bSkipTimeCheck)
{
    if (GRI == none || self.TeamIndex != TeamIndex || !bIsActive || IsBlocked())
    {
        return false;
    }

    if (!CanSpawnRole(GRI.GetRole(TeamIndex, RoleIndex)))
    {
        return false;
    }

    if (VehiclePoolIndex >= 0 && !CanSpawnVehicle(GRI, VehiclePoolIndex, bSkipTimeCheck))
    {
        return false;
    }

    return true;
}

simulated function bool IsActive()
{
    return bIsActive;
}

event Destroyed()
{
    super.Destroyed();

    // We call this so that players' spawns get invalidated if they are set
    // to spawn on this spawn point.
    SetIsActive(false);
}

function SetIsActive(bool bIsActive)
{
    local Controller C;
    local DHPlayer PC;

    self.bIsActive = bIsActive;

    if (!bIsActive)
    {
        // Invalidate spawns, if necessary.
        for (C = Level.ControllerList; C != none; C = C.NextController)
        {
            PC = DHPlayer(C);

            if (PC != none && PC.SpawnPointIndex == SpawnPointIndex)
            {
                PC.SpawnPointIndex = -1;
                PC.bSpawnPointInvalidated = true;
            }
        }
    }
}

// Override to change the button style for display on the deploy menu.
simulated function string GetMapStyleName()
{
    return "DHSpawnButtonStyle";
}

// Override to change the text displayed overtop of the spawn point icon on the map.
simulated function string GetMapText();

// TODO: I don't like this one bit! SEPARATE OUT INTO DIFFERENT FUNCTIONS
function GetPlayerCountsWithinRadius(float RadiusInMeters, optional int SquadIndex, optional out int SquadmateCount, optional out int EnemyCount, optional out int TeammateCount)
{
    local Pawn P;
    local DHPlayerReplicationInfo OtherPRI;

    foreach RadiusActors(class'Pawn', P, class'DHUnits'.static.MetersToUnreal(RadiusInMeters))
    {
        if (P != none && !P.bDeleteMe && P.Health > 0 && P.PlayerReplicationInfo != none)
        {
            if (P.GetTeamNum() == TeamIndex)
            {
                TeammateCount += 1;

                OtherPRI = DHPlayerReplicationInfo(P.PlayerReplicationInfo);

                if (OtherPRI != none && OtherPRI.SquadIndex == SquadIndex)
                {
                    SquadmateCount += 1;
                }
            }
            else
            {
                EnemyCount += 1;
            }
        }
    }
}

simulated final function int GetTeamIndex()
{
    return TeamIndex;
}

final function SetTeamIndex(int TeamIndex)
{
    if (self.TeamIndex != TeamIndex)
    {
        self.TeamIndex = TeamIndex;

        OnTeamIndexChanged();
    }
}

function OnTeamIndexChanged();

defaultproperties
{
    TeamIndex=-1
    SpawnProtectionTime=2.0
    SpawnKillProtectionTime=6.0
    bAlwaysRelevant=true
    RemoteRole=ROLE_SimulatedProxy
    bIsActive=false
    bHidden=true
    SpawnRadiusSegmentCount=8
}

