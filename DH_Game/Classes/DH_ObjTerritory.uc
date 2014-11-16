//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_ObjTerritory extends ROObjTerritory
    placeable;

//--------------------------------------
//Enums & Structs
//--------------------------------------
enum EObjectiveOperation
{
    EOO_Activate,
    EOO_Deactivate,
    EOO_Toggle
};

enum ESpawnPointOperation
{
    ESPO_Enable,
    ESPO_Disable,
    ESPO_Toggle,
};

enum EVehiclePoolOperation
{
    EVPO_Enable,
    EVPO_Disable,
    EVPO_Toggle,
    EVPO_MaxSpawnsAdd,
    EVPO_MaxSpawnsSet,
    EVPO_MaxActiveAdd,
    EVPO_MaxActiveSet
};

struct SpawnPointAction
{
    var() name SpawnPointTag;
    var() ESpawnPointOperation Operation;
};

struct VehiclePoolAction
{
    var() name VehiclePoolTag;
    var() EVehiclePoolOperation Operation;
    var() int Value;
};

struct ObjOperationAction
{
    var() int ObjectiveNum;
    var() EObjectiveOperation Operation;
};

//--------------------------------------
//Variables
//--------------------------------------
var()   bool                        bVehiclesCanCapture;
var()   bool                        bTankersCanCapture;
var()   bool                        bUsePostCaptureOperations; //Enables below variables to be used for post capture clear check/calls
var()   bool                        bDisableWhenAlliesClearObj;
var()   bool                        bDisableWhenAxisClearObj;
var()   bool                        bGroupActionsAtDisable;
var()   int                         PlayersNeededToCapture;

var     bool                        bCheckIfAxisCleared;
var     bool                        bCheckIfAlliesCleared;

//Capture Operations (after capture)
var(DH_CaptureActions)   array<ObjOperationAction>   AlliesCaptureObjActions;
var(DH_CaptureActions)   array<ObjOperationAction>   AxisCaptureObjActions;
var(DH_CaptureActions)   array<SpawnPointAction>     AlliesCaptureSpawnPointActions;
var(DH_CaptureActions)   array<SpawnPointAction>     AxisCaptureSpawnPointActions;
var(DH_CaptureActions)   array<VehiclePoolAction>    AlliesCaptureVehiclePoolActions;
var(DH_CaptureActions)   array<VehiclePoolAction>    AxisCaptureVehiclePoolActions;
var(DH_CaptureActions)   array<name>                 AlliesCaptureEvents;
var(DH_CaptureActions)   array<name>                 AxisCaptureEvents;

//Post Capture Cleared Operations (after capture and cleared of enemies)
var(DH_ClearedActions)   array<ObjOperationAction>   AlliesClearedCaptureObjActions;
var(DH_ClearedActions)   array<ObjOperationAction>   AxisClearedCaptureObjActions;
var(DH_ClearedActions)   array<SpawnPointAction>     AlliesClearedCaptureSpawnPointActions;
var(DH_ClearedActions)   array<SpawnPointAction>     AxisClearedCaptureSpawnPointActions;
var(DH_ClearedActions)   array<VehiclePoolAction>    AlliesClearedCaptureVehiclePoolActions;
var(DH_ClearedActions)   array<VehiclePoolAction>    AxisClearedCaptureVehiclePoolActions;
var(DH_ClearedActions)   array<name>                 AlliesClearedCaptureEvents;
var(DH_ClearedActions)   array<name>                 AxisClearedCaptureEvents;

//Grouped Capture Operations (These will need to be the same in each grouped objective, unless you desire different actions based on the last captured grouped objective)
var(DH_GroupedActions)   array<int>                  GroupedObjectiveReliances; //array of Objective Nums this objective is grouped with (doesn't need to list itself)
var(DH_GroupedActions)   array<ObjOperationAction>   AlliesCaptureGroupObjActions;
var(DH_GroupedActions)   array<ObjOperationAction>   AxisCaptureGroupObjActions;
var(DH_GroupedActions)   array<name>                 AlliesGroupedCaptureEvents;
var(DH_GroupedActions)   array<name>                 AxisGroupedCaptureEvents;

//--------------------------------------
//Functions
//--------------------------------------
function PostBeginPlay()
{
    super.PostBeginPlay();

    //We need this to be less than 15.  We're embedding the amount of players
    //needed into the front end of the CurrentCapArea byte.  If there were 15
    //people needed to capture point index 15, then CurrentCapArea = 0XFF which
    //is the flag for no capture area.  This truncation avoids this and throws
    //a warning for the mapper.
    if (PlayersNeededToCapture > 14)
    {
        Warn(self @ " players needed to capture greater than 14, truncating.");
        PlayersNeededToCapture = 14;
    }
}

function Reset()
{
    Super.Reset();

    bCheckIfAxisCleared = false;
    bCheckIfAlliesCleared = false;
}

function DoSpawnPointAction(SpawnPointAction SPA)
{
    local DHSpawnManager VM;

    VM = DarkestHourGame(Level.Game).SpawnManager;

    switch (SPA.Operation)
    {
        case ESPO_Enable:
            VM.SetSpawnPointIsActiveByTag(SPA.SpawnPointTag, true);
            break;
        case ESPO_Disable:
            VM.SetSpawnPointIsActiveByTag(SPA.SpawnPointTag, false);
            break;
        case ESPO_Toggle:
            VM.ToggleSpawnPointIsActiveByTag(SPA.SpawnPointTag);
            break;
        default:
            Warn("Unhandled ESpawnPointOperation");
            break;
    }
}

function DoVehiclePoolAction(VehiclePoolAction VPA)
{
    local DHSpawnManager VM;

    VM = DarkestHourGame(Level.Game).SpawnManager;

    switch (VPA.Operation)
    {
        case EVPO_Enable:
            VM.SetPoolIsActiveByTag(VPA.VehiclePoolTag, true);
            break;
        case EVPO_Disable:
            VM.SetPoolIsActiveByTag(VPA.VehiclePoolTag, false);
            break;
        case EVPO_Toggle:
            VM.TogglePoolIsActiveByTag(VPA.VehiclePoolTag);
            break;
        case EVPO_MaxSpawnsAdd:
            VM.AddPoolMaxSpawnsByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        case EVPO_MaxSpawnsSet:
            VM.SetPoolMaxSpawnsByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        case EVPO_MaxActiveAdd:
            VM.AddPoolMaxActiveByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        case EVPO_MaxActiveSet:
            VM.SetPoolMaxActiveByTag(VPA.VehiclePoolTag, VPA.Value);
            break;
        default:
            Warn("Unhandled EVehiclePoolOperation");
            break;
    }
}

function DoObjectiveAction(ObjOperationAction OOA)
{
    local bool ToggledStatus;
    local DarkesthourGame DHGame;

    DHGame = DarkesthourGame(Level.Game);

    switch (OOA.Operation)
    {
        case EOO_Activate:
            DHGame.Objectives[OOA.ObjectiveNum].SetActive(true);
            break;
        case EOO_Deactivate:
            DHGame.Objectives[OOA.ObjectiveNum].SetActive(false);
            break;
        case EOO_Toggle:
            ToggledStatus = !DHGame.Objectives[OOA.ObjectiveNum].bActive;
            DHGame.Objectives[OOA.ObjectiveNum].SetActive(ToggledStatus);
            break;
        default:
            Warn("Unhandled EObjectiveOperation");
            break;
    }
}

function HandleGroupActions(int Team)
{
    local int i;
    local bool bGroupedObjNotSame;
    local DarkesthourGame DHGame;

    DHGame = DarkesthourGame(Level.Game);

    if(Team == AXIS_TEAM_INDEX)
    {
        for (i = 0; i < GroupedObjectiveReliances.Length; ++i)
        {
            //Check if the grouped objective isn't captured for Axis
            if (!DHGame.Objectives[GroupedObjectiveReliances[i]].isAxis())
            {
                //One of the grouped objectives is not captured for Axis yet
                bGroupedObjNotSame = true;
            }
        }

        //If all the grouped objectives are captured for Axis, do grouped actions
        if (GroupedObjectiveReliances.Length > 0 && !bGroupedObjNotSame)
        {
            for (i = 0; i < AxisCaptureGroupObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisCaptureGroupObjActions[i]);
            }

            for (i = 0; i < AxisGroupedCaptureEvents.Length; ++i)
            {
                TriggerEvent(AxisGroupedCaptureEvents[i], none, none);
            }
        }
    }
    else if (Team == ALLIES_TEAM_INDEX)
    {
        for (i = 0; i < GroupedObjectiveReliances.Length; ++i)
        {
            //Check if the grouped objective isn't captured for Allies
            if (!DHGame.Objectives[GroupedObjectiveReliances[i]].isAllies())
            {
                //One of the grouped objectives is not captured for Allies yet
                bGroupedObjNotSame = true;
            }
        }

        //If all the grouped objectives are captured for Allies, do grouped actions
        if (GroupedObjectiveReliances.Length > 0 && !bGroupedObjNotSame)
        {
            for (i = 0; i < AlliesCaptureGroupObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesCaptureGroupObjActions[i]);
            }

            for (i = 0; i < AlliesGroupedCaptureEvents.Length; ++i)
            {
                TriggerEvent(AlliesGroupedCaptureEvents[i], none, none);
            }
        }
    }

}

function HandleCompletion(PlayerReplicationInfo CompletePRI, int Team)
{
    local int i;
    local Controller C;
    local Pawn P;
    local DHPlayerReplicationInfo PRI;
    local DH_RoleInfo RI;
    local DarkesthourGame DHGame;
    local DHSpawnManager VM;

    DHGame = DarkesthourGame(Level.Game);
    VM = DHGame.SpawnManager;

    //I think we need some type of check here if DHGame == None or VM Theel Debug

    CurrentCapProgress = 0.0;

    // If it's not recapturable, make it inactive
    if (!bRecaptureable)
    {
        bActive = false;

        //Only turn off the timer if bUsePostCaptureOperations is false, we will turn it off after it's clear of enemies (in timer)
        if (!bUsePostCaptureOperations)
        {
            SetTimer(0.0, false);
        }

        DisableCapBarsForThisObj(); //Might want to move this to above if statement, but would need testing
    }

    // Give players points for helping with the capture
    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        P = DH_Pawn(C.Pawn);

        if (P == none)
        {
            P = ROVehicle(C.Pawn);

            if (P == none)
            {
                P = ROVehicleWeaponPawn(C.Pawn);

                // This check might be a little redundant, since we do it in the next line - Ramm
                if (P == none)
                    continue;
                else if (!bVehiclesCanCapture)
                    continue;
            }
            else if (!bVehiclesCanCapture)
            {
                continue;
            }
        }

        PRI = DHPlayerReplicationInfo(C.PlayerReplicationInfo);
        RI = DH_RoleInfo(PRI.RoleInfo);

        if (!C.bIsPlayer || P == none || !WithinArea(P) || C.PlayerReplicationInfo.Team == none || C.PlayerReplicationInfo.Team.TeamIndex != Team)
            continue;

        if (!bTankersCanCapture && (RI.bCanBeTankCrew || RI.bCanBeTankCommander))
            continue;

        Level.Game.ScoreObjective(C.PlayerReplicationInfo, 10);
    }

    BroadcastLocalizedMessage(class'DHObjectiveMsg', Team, none, none, self);

    switch (Team)
    {
        case AXIS_TEAM_INDEX:
            for (i = 0; i < AxisCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisCaptureObjActions[i]);
            }

            for (i = 0; i < AxisCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AxisCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisCaptureVehiclePoolActions[i]);
            }

            for (i = 0; i < AxisCaptureEvents.Length; ++i)
            {
                TriggerEvent(AxisCaptureEvents[i], none, none);
            }

            //Do a check for the post capture clear system
            if (bUsePostCaptureOperations)
            {
                bCheckIfAxisCleared = false; //stop checking for when Axis are cleared (supports recapturable objectives)
                bCheckIfAlliesCleared = true; //begin checking for when Allies are cleared
            }

            if (!bGroupActionsAtDisable)
            {
                HandleGroupActions(AXIS_TEAM_INDEX);
            }
            break;
        case ALLIES_TEAM_INDEX:
            for (i = 0; i < AlliesCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesCaptureObjActions[i]);
            }

            for (i = 0; i < AlliesCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesCaptureVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesCaptureEvents.Length; ++i)
            {
                TriggerEvent(AlliesCaptureEvents[i], none, none);
            }

            //Do a check for the post capture clear system
            if (bUsePostCaptureOperations)
            {
                bCheckIfAlliesCleared = false; //stop checking for when Allies are cleared (supports recapturable objectives)
                bCheckIfAxisCleared = true; //begin checking for when Axis are cleared
            }

            if (!bGroupActionsAtDisable)
            {
                HandleGroupActions(ALLIES_TEAM_INDEX);
            }
            break;
    }
}

function Timer()
{
    local byte CP;
    local int NumTotal[2], Num[2], NumForCheck[2], i;
    local Controller C;
    local Pawn pawn;
    local DH_Pawn P;
    local float LeaderBonus[2], Rate[2];
    local ROVehicle ROVeh;
    local ROVehicleWeaponPawn VehWepPawn;
    local float oldCapProgress;
    local Controller firstCapturer;
    local byte CurrentCapAxisCappers, CurrentCapAlliesCappers;
    local ROPlayerReplicationInfo PRI;
    local DH_RoleInfo RI;

    if((ROTeamGame(Level.Game) == none || !ROTeamGame(Level.Game).IsInState('RoundInPlay')) || (!bActive && !bUsePostCaptureOperations))
    {
        return;
    }

    //Some RO code (that is retarded)
    LeaderBonus[AXIS_TEAM_INDEX] = 1.0;
    LeaderBonus[ALLIES_TEAM_INDEX] = 1.0;

    // Loop through the Controller list and determine how many players from each team are inside the attached volume, if any, or if there is no volume,
    // within the Radius that was set.
    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        if (C.bIsPlayer && C.PlayerReplicationInfo.Team != none && ((ROPlayer(C) != none && ROPlayer(C).GetRoleInfo() != none) || ROBot(C) != none))
        {
            pawn = C.Pawn;
            P = DH_Pawn(C.Pawn);
            ROVeh = ROVehicle(C.Pawn);
            VehWepPawn = ROVehicleWeaponPawn(C.Pawn);

            PRI = ROPlayerReplicationInfo(C.PlayerReplicationInfo);
            RI = DH_RoleInfo(PRI.RoleInfo);

            if (pawn != none && pawn.Health > 0 && WithinArea(pawn))
            {
                if ((!bTankersCanCapture && RI != none && (RI.bCanBeTankCrew || RI.bCanBeTankCommander)) ||
                (!bVehiclesCanCapture && (ROVeh != none || VehWepPawn != none)))
                {
                    pawn = none;
                    continue;
                }

                if (RI != none && RI.bIsSquadLeader)
                    LeaderBonus[C.PlayerReplicationInfo.Team.TeamIndex] = 2.0;

                Num[C.PlayerReplicationInfo.Team.TeamIndex]++;

                if (RI != none)
                    NumForCheck[C.PlayerReplicationInfo.Team.TeamIndex] += PRI.RoleInfo.ObjCaptureWeight;
                else
                    NumForCheck[C.PlayerReplicationInfo.Team.TeamIndex]++;

                firstCapturer = C;  // Used so that first person to initiate capture doesn't get the 'map updated' notification

                // Leader bonuses are given to a side if a leader is there
            }

            // Fixes the cap bug
            pawn = none;

            // Update total nums
            NumTotal[C.PlayerReplicationInfo.Team.TeamIndex]++;
        }
    }

    //Now that we calculated how many of each team is in the objective, lets do the bUsePostCaptureOperations checks
    if (bUsePostCaptureOperations)
    {
        if (bCheckIfAxisCleared && NumForCheck[0] <= 0)
        {
            //IT IS CLEARED OF AXIS (SO DO ALLIES ACTIONS)
            bCheckIfAxisCleared = false; //Stop checking

            for (i = 0; i < AlliesClearedCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AlliesClearedCaptureObjActions[i]);
            }

            for (i = 0; i < AlliesClearedCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AlliesClearedCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AlliesClearedCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AlliesClearedCaptureVehiclePoolActions[i]);
            }

            for (i = 0; i < AlliesClearedCaptureEvents.Length; ++i)
            {
                TriggerEvent(AlliesClearedCaptureEvents[i], none, none);
            }

            if (bGroupActionsAtDisable)
            {
                HandleGroupActions(ALLIES_TEAM_INDEX);
            }

            if (bDisableWhenAlliesClearObj)
            {
                //log("DEBUG Disable Objective Because Allies Cleared It");
                bActive = false;
                SetTimer(0.0, false);
                DisableCapBarsForThisObj();
                return;
            }
            else if (!bRecaptureable)
            {
                SetTimer(0.0, false);
                return;
            }
        }
        if (bCheckIfAlliesCleared && NumForCheck[1] <= 0)
        {
            //IT IS CLEARED OF ALLIES (SO DO AXIS ACTIONS)
            bCheckIfAlliesCleared = false; //Stop checking

            for (i = 0; i < AxisClearedCaptureObjActions.Length; ++i)
            {
                DoObjectiveAction(AxisClearedCaptureObjActions[i]);
            }

            for (i = 0; i < AxisClearedCaptureSpawnPointActions.Length; ++i)
            {
                DoSpawnPointAction(AxisClearedCaptureSpawnPointActions[i]);
            }

            for (i = 0; i < AxisClearedCaptureVehiclePoolActions.Length; ++i)
            {
                DoVehiclePoolAction(AxisClearedCaptureVehiclePoolActions[i]);
            }

            if (bGroupActionsAtDisable)
            {
                HandleGroupActions(AXIS_TEAM_INDEX);
            }

            if (bDisableWhenAxisClearObj)
            {
                //log("DEBUG Disable Objective Because Axis Cleared It");
                bActive = false;
                SetTimer(0.0, false);
                DisableCapBarsForThisObj();
                return;
            }
            else if (!bRecaptureable)
            {
                SetTimer(0.0, false);
                return;
            }
        }
    }

    //Do nothing else if it's not active
    if (!bActive)
        return;

    oldCapProgress = CurrentCapProgress;

    // Figure out the rate of capture that each side is capable of
    // Rate is defined as:
    // Number of players in the area * BaseCaptureRate * Leader bonus (if any) * Percentage of players on the team in the area
    for (i = 0; i < 2; i++)
    {
        if (Num[i] >= PlayersNeededToCapture)
            Rate[i] = FMin(Num[i] * BaseCaptureRate * LeaderBonus[i] * (float(Num[i]) / NumTotal[i]), MaxCaptureRate);
        else
            Rate[i] = 0.0;
    }

    // Figure what the replicated # of cappers should be (to take into account
    // the leader bonus)
    CurrentCapAxisCappers = NumForCheck[AXIS_TEAM_INDEX]; // * int(4.0 * LeaderBonus[AXIS_TEAM_INDEX]);
    CurrentCapAlliesCappers = NumForCheck[ALLIES_TEAM_INDEX]; // * int(4.0 * LeaderBonus[ALLIES_TEAM_INDEX]);

    // Note: Comparing number of players as opposed to rates to decide which side has the advantage for
    // the capture for fear that rates could be abused in this instance
    if (ObjState != OBJ_Axis && NumForCheck[AXIS_TEAM_INDEX] > NumForCheck[ALLIES_TEAM_INDEX])
    {
        // Have to work down the progress the other team made first, but this is quickened since
        // the fall off rate still occurs
        if (CurrentCapTeam == ALLIES_TEAM_INDEX)
        {
            CurrentCapProgress -= 0.25 * (FallOffRate + Rate[AXIS_TEAM_INDEX]);
        }
        else
        {
            CurrentCapTeam = AXIS_TEAM_INDEX;
            CurrentCapProgress += 0.25 * Rate[AXIS_TEAM_INDEX];
        }
    }
    else if (ObjState != OBJ_Allies && NumForCheck[ALLIES_TEAM_INDEX] > NumForCheck[AXIS_TEAM_INDEX])
    {
        if (CurrentCapTeam == AXIS_TEAM_INDEX)
        {
            CurrentCapProgress -= 0.25 * (FallOffRate + Rate[ALLIES_TEAM_INDEX]);
        }
        else
        {
            CurrentCapTeam = ALLIES_TEAM_INDEX;
            CurrentCapProgress += 0.25 * Rate[ALLIES_TEAM_INDEX];
        }
    }
    else if (NumForCheck[ALLIES_TEAM_INDEX] == NumForCheck[AXIS_TEAM_INDEX] && NumForCheck[AXIS_TEAM_INDEX] != 0)
    {
        // Stalemate! No change.
    }
    else
    {
        CurrentCapProgress -= 0.25 * FallOffRate;
    }

    CurrentCapProgress = FClamp(CurrentCapProgress, 0.0, 1.0);

    if (CurrentCapProgress == 0.0)
        CurrentCapTeam = NEUTRAL_TEAM_INDEX;
    else if (CurrentCapProgress == 1.0)
        ObjectiveCompleted(none, CurrentCapTeam);

    // Go through and update capture bars
    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        P = DH_Pawn(C.Pawn);
        ROVeh = ROVehicle(C.Pawn);
        VehWepPawn = ROVehicleWeaponPawn(C.Pawn);

        if (!C.bIsPlayer)
        {
            continue;
        }

        if (P != none)
        {
            if (!bActive || !WithinArea(P))
            {
                if ((P.CurrentCapArea & 0x0F) == ObjNum)
                    P.CurrentCapArea = 255;
            }
            else
            {
                if (P.CurrentCapArea != (ObjNum + (PlayersNeededToCapture << 4)))
                    P.CurrentCapArea = (ObjNum + (PlayersNeededToCapture << 4));

                CP = byte(Ceil(CurrentCapProgress * 100));

                // Hack to save on variables replicated (if Allies, add 100 so the range is 101-200 instead of 1-100, or just 0 if it is 0)
                if (CurrentCapTeam == ALLIES_TEAM_INDEX && CurrentCapProgress != 0.0)
                    CP += 100;

                if (P.CurrentCapProgress != CP)
                    P.CurrentCapProgress = CP;

                // Replicate # of players in capture zone
                if (P.CurrentCapAxisCappers != CurrentCapAxisCappers)
                    P.CurrentCapAxisCappers = CurrentCapAxisCappers;
                if (P.CurrentCapAlliesCappers != CurrentCapAlliesCappers)
                    P.CurrentCapAlliesCappers = CurrentCapAlliesCappers;
            }
        }

        // Draw the capture bar for rovehicles and rovehiclepawns
        if (P == none && ROVeh != none)
        {
            if (!bActive || !WithinArea(ROVeh))
            {
                if ((ROVeh.CurrentCapArea & 0x0F) == ObjNum)
                    ROVeh.CurrentCapArea = 255;
            }
            else
            {
                if (ROVeh.CurrentCapArea != (ObjNum + (PlayersNeededToCapture << 4)))
                    ROVeh.CurrentCapArea = (ObjNum + (PlayersNeededToCapture << 4));

                CP = byte(Ceil(CurrentCapProgress * 100));

                // Hack to save on variables replicated (if Allies, add 100 so the range is 101-200 instead of 1-100, or just 0 if it is 0)
                if (CurrentCapTeam == ALLIES_TEAM_INDEX && CurrentCapProgress != 0.0)
                    CP += 100;

                if (ROVeh.CurrentCapProgress != CP)
                    ROVeh.CurrentCapProgress = CP;

                // Replicate # of players in capture zone
                if (ROVeh.CurrentCapAxisCappers != CurrentCapAxisCappers)
                    ROVeh.CurrentCapAxisCappers = CurrentCapAxisCappers;
                if (ROVeh.CurrentCapAlliesCappers != CurrentCapAlliesCappers)
                    ROVeh.CurrentCapAlliesCappers = CurrentCapAlliesCappers;
            }
        }

        if (P == none && ROVeh == none && VehWepPawn != none)
        {
            if (!bActive || !WithinArea(VehWepPawn))
            {
                if ((VehWepPawn.CurrentCapArea & 0x0F) == ObjNum)
                    VehWepPawn.CurrentCapArea = 255;
            }
            else
            {
                if (VehWepPawn.CurrentCapArea != (ObjNum + (PlayersNeededToCapture << 4)))
                    VehWepPawn.CurrentCapArea = (ObjNum + (PlayersNeededToCapture << 4));

                CP = byte(Ceil(CurrentCapProgress * 100));

                // Hack to save on variables replicated (if Allies, add 100 so the range is 101-200 instead of 1-100, or just 0 if it is 0)
                if (CurrentCapTeam == ALLIES_TEAM_INDEX && CurrentCapProgress != 0.0)
                    CP += 100;

                if (VehWepPawn.CurrentCapProgress != CP)
                    VehWepPawn.CurrentCapProgress = CP;

                // Replicate # of players in capture zone
                if (VehWepPawn.CurrentCapAxisCappers != CurrentCapAxisCappers)
                    VehWepPawn.CurrentCapAxisCappers = CurrentCapAxisCappers;
                if (VehWepPawn.CurrentCapAlliesCappers != CurrentCapAlliesCappers)
                    VehWepPawn.CurrentCapAlliesCappers = CurrentCapAlliesCappers;
            }
        }
    }

    // Check if we should send map info change notification to players
    if (!(oldCapProgress ~= CurrentCapProgress))
    {
        // Check if we changed from 1.0 or from 0.0 (no need to send events
        // otherwise)
        if (oldCapProgress ~= 0 || oldCapProgress ~= 1)
            ROTeamGame(Level.Game).NotifyPlayersOfMapInfoChange(NEUTRAL_TEAM_INDEX, firstCapturer);
    }

    UpdateCompressedCapProgress();
}

//Theel: Overridden to correctly turn off capture bars for DH objective areas
function DisableCapBarsForThisObj()
{
    local Pawn apawn;
    local ROPawn P;
    local ROVehicle ROVeh;
    local ROVehicleWeaponPawn VehWepPawn;

    // Go through and update capture bars
    foreach DynamicActors(class'pawn', apawn)
    {
        P = ROPawn(apawn);
        ROVeh = ROVehicle(apawn);
        VehWepPawn = ROVehicleWeaponPawn(apawn);

        if ( P != none )
        {
            //Log("P.CurrentCapArea & 0x0F: " $ (P.CurrentCapArea & 0x0F) @ "ObjNum: " $ ObjNum);
            if ((P.CurrentCapArea & 0x0F) == ObjNum)
                P.CurrentCapArea = 255;
        }

        // Disable the capture bar for rovehicles
        if (  P == none && ROVeh != none )
        {
            if ((ROVeh.CurrentCapArea & 0x0F) == ObjNum)
                ROVeh.CurrentCapArea = 255;
        }

        // Disable the capture bar for rovehiclepawns
        if (  P == none && ROVeh == none && VehWepPawn != none)
        {
            if ((VehWepPawn.CurrentCapArea & 0x0F) == ObjNum)
                VehWepPawn.CurrentCapArea = 255;
        }
    }
}

defaultproperties
{
     bVehiclesCanCapture=true
     bTankersCanCapture=true
     PlayersNeededToCapture=1
}
