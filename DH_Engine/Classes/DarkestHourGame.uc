//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DarkestHourGame extends ROTeamGame;

var     DH_LevelInfo                DHLevelInfo;

var     DHAmmoResupplyVolume        DHResupplyAreas[10];

var     array<DHSpawnArea>          DHMortarSpawnAreas;
var     DHSpawnArea                 DHCurrentMortarSpawnArea[2];

var     DH_RoleInfo                 DHAxisRoles[16];
var     DH_RoleInfo                 DHAlliesRoles[16];

var     DHSpawnManager              SpawnManager;
var     DHObstacleManager           ObstacleManager;

var     array<string>               FFViolationIDs; //Array of ROIDs that have been kicked once this session
var()   config bool                 bSessionKickOnSecondFFViolation;

var     class<DHObstacleManager>    ObstacleManagerClass;

// Overridden to make new clamp of MaxPlayers from 64 to 128
event InitGame(string Options, out string Error)
{
    super.InitGame(Options, Error);

    if (bIgnore32PlayerLimit)
    {
        MaxPlayers = Clamp(GetIntOption(Options, "MaxPlayers", MaxPlayers), 0, 128);
        default.MaxPlayers = Clamp(default.MaxPlayers, 0, 128);
    }
}

function PostBeginPlay()
{
    local DHGameReplicationInfo DHGRI;
    local DH_LevelInfo          DLI;
    local ROLevelInfo           LI;
    local ROMapBoundsNE         NE;
    local ROMapBoundsSW         SW;
    local DHSpawnArea           DHSA;
    local DHAmmoResupplyVolume  ARV;
    local ROMineVolume          MV;
    local ROArtilleryTrigger    RAT;
    local SpectatorCam          ViewPoint;
    local int                   i, j, k, m, n, o, p;
    local DHObstacleInfo        DHOI;

    // Don't call the RO super because we already do everything for DH and don't
    // want levels using ROLevelInfo
    super(TeamGame).PostBeginPlay();

    Level.bKickLiveIdlers = MaxIdleTime > 0.0;

    // Find the ROLevelInfo
    foreach AllActors(class'ROLevelInfo', LI)
    {
        if (LevelInfo == none)
        {
            LevelInfo = LI;
        }
        else
        {
            Log("DarkestHourGame: More than one ROLevelInfo detected!");
            break;
        }
    }

    // Find the DH_LevelInfo
    foreach AllActors(class'DH_LevelInfo', DLI)
    {
        if (DHLevelInfo != none)
        {
            Log("DarkestHourGame: More than one DH_LevelInfo detected!");
            break;
        }

        DHLevelInfo = DLI;
    }

    foreach AllActors(class'DHObstacleInfo', DHOI)
    {
        ObstacleManager = Spawn(ObstacleManagerClass);
        break;
    }

    // Darkest Hour Game Check
    // Prevents ROLevelInfo from working with DH levels
    if (LevelInfo == none || !LevelInfo.IsA('DH_LevelInfo'))
    {
        Warn("DarkestHourGame: No DH_LevelInfo detected!");
        Warn("Level may not be using DH_LevelInfo and needs to be!");

        return; // don't setup the game if LevelInfo isn't DH
    }

    //We made it here so lets setup our DarkestHourGame

    // Setup spectator viewpoints
    for (n = 0; n < LevelInfo.EntryCamTags.Length; ++n)
    {
        foreach AllActors(class'SpectatorCam', ViewPoint, LevelInfo.EntryCamTags[n])
        {
            ViewPoints[ViewPoints.Length] = ViewPoint;
        }
    }

    RoundDuration = LevelInfo.RoundDuration * 60;

    // Setup some GRI stuff
    DHGRI = DHGameReplicationInfo(GameReplicationInfo);

    if (DHGRI == none)
    {
        return;
    }

    DHGRI.bAllowNetDebug = bAllowNetDebug;
    DHGRI.PreStartTime = PreStartTime;
    DHGRI.RoundDuration = RoundDuration;
    DHGRI.bReinforcementsComing[AXIS_TEAM_INDEX] = 0;
    DHGRI.bReinforcementsComing[ALLIES_TEAM_INDEX] = 0;
    DHGRI.ReinforcementInterval[AXIS_TEAM_INDEX] = LevelInfo.Axis.ReinforcementInterval;
    DHGRI.ReinforcementInterval[ALLIES_TEAM_INDEX] = LevelInfo.Allies.ReinforcementInterval;
    DHGRI.UnitName[AXIS_TEAM_INDEX] = LevelInfo.Axis.UnitName;
    DHGRI.UnitName[ALLIES_TEAM_INDEX] = LevelInfo.Allies.UnitName;
    DHGRI.NationIndex[AXIS_TEAM_INDEX] = LevelInfo.Axis.Nation;
    DHGRI.NationIndex[ALLIES_TEAM_INDEX] = LevelInfo.Allies.Nation;
    DHGRI.UnitInsignia[AXIS_TEAM_INDEX] = LevelInfo.Axis.UnitInsignia;
    DHGRI.UnitInsignia[ALLIES_TEAM_INDEX] = LevelInfo.Allies.UnitInsignia;
    DHGRI.MapImage = LevelInfo.MapImage;
    DHGRI.bPlayerMustReady = bPlayersMustBeReady;
    DHGRI.RoundLimit = RoundLimit;
    DHGRI.MaxPlayers = MaxPlayers;
    DHGRI.bShowServerIPOnScoreboard = bShowServerIPOnScoreboard;
    DHGRI.bShowTimeOnScoreboard = bShowTimeOnScoreboard;

    // Artillery
    DHGRI.ArtilleryStrikeLimit[AXIS_TEAM_INDEX] = LevelInfo.Axis.ArtilleryStrikeLimit;
    DHGRI.ArtilleryStrikeLimit[ALLIES_TEAM_INDEX] = LevelInfo.Allies.ArtilleryStrikeLimit;
    DHGRI.bArtilleryAvailable[AXIS_TEAM_INDEX] = 0;
    DHGRI.bArtilleryAvailable[ALLIES_TEAM_INDEX] = 0;
    DHGRI.LastArtyStrikeTime[AXIS_TEAM_INDEX] = LevelInfo.GetStrikeInterval(AXIS_TEAM_INDEX);
    DHGRI.LastArtyStrikeTime[ALLIES_TEAM_INDEX] = LevelInfo.GetStrikeInterval(ALLIES_TEAM_INDEX);
    DHGRI.TotalStrikes[AXIS_TEAM_INDEX] = 0;
    DHGRI.TotalStrikes[ALLIES_TEAM_INDEX] = 0;

    for (k = 0; k < arraycount(DHGRI.AxisRallyPoints); ++k)
    {
        DHGRI.AlliedRallyPoints[k].OfficerPRI = none;
        DHGRI.AlliedRallyPoints[k].RallyPointLocation = vect(0.0, 0.0, 0.0);
        DHGRI.AxisRallyPoints[k].OfficerPRI = none;
        DHGRI.AxisRallyPoints[k].RallyPointLocation = vect(0.0, 0.0, 0.0);
    }

    // Clear help requests array
    for (k = 0; k < arraycount(DHGRI.AlliedHelpRequests); ++k)
    {
        DHGRI.AlliedHelpRequests[k].OfficerPRI = none;
        DHGRI.AlliedHelpRequests[k].requestType = 255;
        DHGRI.AxisHelpRequests[k].OfficerPRI = none;
        DHGRI.AxisHelpRequests[k].requestType = 255;
    }

    ResetMortarTargets();

    if (LevelInfo.OverheadOffset == OFFSET_90)
    {
        DHGRI.OverheadOffset = 90;
    }
    else if (LevelInfo.OverheadOffset == OFFSET_180)
    {
        DHGRI.OverheadOffset = 180;
    }
    else if (LevelInfo.OverheadOffset == OFFSET_270)
    {
        DHGRI.OverheadOffset = 270;
    }
    else
    {
        DHGRI.OverheadOffset = 0;
    }

    // Store allied nationality for customising HUD
    if (DHLevelInfo.AlliedNation == NATION_Britain)
    {
        DHGRI.AlliedNationID = 1;
    }
    else if (DHLevelInfo.AlliedNation == NATION_Canada)
    {
        DHGRI.AlliedNationID = 2;
    }
    else
    {
        DHGRI.AlliedNationID = 0;
    }

    // Find the location of the map bounds
    foreach AllActors(class'ROMapBoundsNE', NE)
    {
        DHGRI.NorthEastBounds = NE.Location;
    }
    foreach AllActors(class'ROMapBoundsSW', SW)
    {
        DHGRI.SouthWestBounds = SW.Location;
    }

    // Find all the radios
    foreach AllActors(class'ROArtilleryTrigger', RAT)
    {
        if (RAT.TeamCanUse == AT_Axis || RAT.TeamCanUse == AT_Both)
        {
            DHGRI.AxisRadios[i] = RAT;
            i++;
        }
    }

    foreach AllActors(class'ROArtilleryTrigger', RAT)
    {
        if (RAT.TeamCanUse == AT_Allies || RAT.TeamCanUse == AT_Both)
        {
            DHGRI.AlliedRadios[j] = RAT;
            j++;
        }
    }

    foreach AllActors(class'DHAmmoResupplyVolume', ARV)
    {
        DHResupplyAreas[m] = ARV;
        DHGRI.ResupplyAreas[m].ResupplyVolumeLocation = ARV.Location;
        DHGRI.ResupplyAreas[m].Team = ARV.Team;
        DHGRI.ResupplyAreas[m].bActive = !ARV.bUsesSpawnAreas;

        if (ARV.ResupplyType == RT_Players)
        {
            DHGRI.ResupplyAreas[m].ResupplyType = 0;
        }
        else if (ARV.ResupplyType == RT_Vehicles)
        {
            DHGRI.ResupplyAreas[m].ResupplyType = 1;
        }
        else if (ARV.ResupplyType == RT_All)
        {
            DHGRI.ResupplyAreas[m].ResupplyType = 2;
        }

        m++;
    }

    foreach AllActors(class'ROMineVolume', MV)
    {
        MineVolumes[o] = MV;
        o++;
    }

    // Added for our overridden DHSpawnArea class - saves me having to check in subsequent functions repeatedly, just lay 'em all out here once
    foreach AllActors(class'DHSpawnArea', DHSA)
    {
        if (DHSA.bMortarmanSpawnArea)
        {
            DHMortarSpawnAreas[p++] = DHSA;
        }
    }

    // Make sure MaxTeamDifference is an acceptable value
    if (MaxTeamDifference < 1)
    {
        MaxTeamDifference = 1;
    }

    foreach AllActors(class'DHSpawnManager', SpawnManager)
    {
        break;
    }

    if (SpawnManager == none)
    {
        Warn("DHSpawnManager could not be found");
    }

    // Here we see if the victory music is set to a sound group and pick an index to replicate to the clients
    if (DHLevelInfo.AlliesWinsMusic != none && DHLevelInfo.AlliesWinsMusic.IsA('SoundGroup'))
    {
        DHGRI.AlliesVictoryMusicIndex = Rand(SoundGroup(DHLevelInfo.AlliesWinsMusic).Sounds.Length - 1);
    }

    if (DHLevelInfo.AxisWinsMusic != none && DHLevelInfo.AxisWinsMusic.IsA('SoundGroup'))
    {
        DHGRI.AxisVictoryMusicIndex = Rand(SoundGroup(DHLevelInfo.AxisWinsMusic).Sounds.Length - 1);
    }
}

function CheckResupplyVolumes()
{
    local DHGameReplicationInfo DHGRI;
    local int i;

    // Activate any resupply areas that are activated based on spawn areas
    DHGRI = DHGameReplicationInfo(GameReplicationInfo);

    for (i = 0; i < arraycount(DHResupplyAreas); ++i)
    {
        if (DHResupplyAreas[i] == none)
        {
            continue;
        }

        if (DHResupplyAreas[i].bUsesSpawnAreas)
        {
            if (DHResupplyAreas[i].Team == AXIS_TEAM_INDEX)
            {
                if ((CurrentTankCrewSpawnArea[AXIS_TEAM_INDEX] != none && CurrentTankCrewSpawnArea[AXIS_TEAM_INDEX].Tag == DHResupplyAreas[i].Tag)
                    || CurrentSpawnArea[AXIS_TEAM_INDEX].Tag == DHResupplyAreas[i].Tag)
                {
                    DHGRI.ResupplyAreas[i].bActive = true;
                    DHResupplyAreas[i].bActive = true;
                }
                else
                {
                    DHGRI.ResupplyAreas[i].bActive = false;
                    DHResupplyAreas[i].bActive = false;
                }
            }

            if (DHResupplyAreas[i].Team == ALLIES_TEAM_INDEX)
            {
                if ((CurrentTankCrewSpawnArea[ALLIES_TEAM_INDEX] != none && CurrentTankCrewSpawnArea[ALLIES_TEAM_INDEX].Tag == DHResupplyAreas[i].Tag)
                    || CurrentSpawnArea[ALLIES_TEAM_INDEX].Tag == DHResupplyAreas[i].Tag)
                {
                    DHGRI.ResupplyAreas[i].bActive = true;
                    DHResupplyAreas[i].bActive = true;
                }
                else
                {
                    DHGRI.ResupplyAreas[i].bActive = false;
                    DHResupplyAreas[i].bActive = false;
                }
            }
        }
        else
        {
            DHGRI.ResupplyAreas[i].bActive = true;
            DHResupplyAreas[i].bActive = true;
        }
    }
}

function CheckMortarmanSpawnAreas()
{
    local DHSpawnArea Best[2];
    local bool        bReqsMet, bSomeReqsMet;
    local int         i, j, h, k;

    for (i = 0; i < DHMortarSpawnAreas.Length; ++i)
    {
        if (!DHMortarSpawnAreas[i].bEnabled)
        {
            continue;
        }

        // Axis plus: either no best or this one has higher precedence
        if (DHMortarSpawnAreas[i].bAxisSpawn && (Best[AXIS_TEAM_INDEX] == none || DHMortarSpawnAreas[i].AxisPrecedence > Best[AXIS_TEAM_INDEX].AxisPrecedence))
        {
            bReqsMet = true;
            bSomeReqsMet = false;

            for (j = 0; j < DHMortarSpawnAreas[i].AxisRequiredObjectives.Length; ++j)
            {
                if (Objectives[DHMortarSpawnAreas[i].AxisRequiredObjectives[j]].ObjState != OBJ_Axis)
                {
                    bReqsMet = false;
                    break;
                }
            }

            for (h = 0; h < DHMortarSpawnAreas[i].AxisRequiredObjectives.Length; ++h)
            {
                if (Objectives[DHMortarSpawnAreas[i].AxisRequiredObjectives[h]].ObjState == OBJ_Axis)
                {
                    bSomeReqsMet = true;
                    break;
                }
            }

            if (DHMortarSpawnAreas[i].bIncludeNeutralObjectives)
            {
                for (k = 0; k < DHMortarSpawnAreas[i].NeutralRequiredObjectives.Length; ++k)
                {
                    if (Objectives[DHMortarSpawnAreas[i].NeutralRequiredObjectives[k]].ObjState == OBJ_Neutral)
                    {
                        bSomeReqsMet = true;
                        break;
                    }
                }
            }

            if (bReqsMet)
            {
                Best[AXIS_TEAM_INDEX] = DHMortarSpawnAreas[i];
            }
            else if (bSomeReqsMet && DHMortarSpawnAreas[i].TeamMustLoseAllRequired == SPN_Axis)
            {
                Best[AXIS_TEAM_INDEX] = DHMortarSpawnAreas[i];
            }
        }

        // Allies plus: either no best or this one has higher precedence
        if (DHMortarSpawnAreas[i].bAlliesSpawn && (Best[ALLIES_TEAM_INDEX] == none || DHMortarSpawnAreas[i].AlliesPrecedence > Best[ALLIES_TEAM_INDEX].AlliesPrecedence))
        {
            bReqsMet = true;
            bSomeReqsMet = false;

            for (j = 0; j < DHMortarSpawnAreas[i].AlliesRequiredObjectives.Length; ++j)
            {
                if (Objectives[DHMortarSpawnAreas[i].AlliesRequiredObjectives[j]].ObjState != OBJ_Allies)
                {
                    bReqsMet = false;
                    break;
                }
            }

            // Added in conjunction with TeamMustLoseAllRequired enum in SpawnAreas
            // Allows Mappers to force all objectives to be lost/won before moving spawns, instead of just one - Ramm
            for (h = 0; h < DHMortarSpawnAreas[i].AlliesRequiredObjectives.Length; ++h)
            {
                if (Objectives[DHMortarSpawnAreas[i].AlliesRequiredObjectives[h]].ObjState == OBJ_Allies)
                {
                    bSomeReqsMet = true;
                    break;
                }
            }

            // Added in conjunction with bIncludeNeutralObjectives in SpawnAreas
            // Allows mappers to have spawns be used when objectives are neutral, not just captured
            if (DHMortarSpawnAreas[i].bIncludeNeutralObjectives)
            {
                for (k = 0; k < DHMortarSpawnAreas[i].NeutralRequiredObjectives.Length; ++k)
                {
                    if (Objectives[DHMortarSpawnAreas[i].NeutralRequiredObjectives[k]].ObjState == OBJ_Neutral)
                    {
                        bSomeReqsMet = true;
                        break;
                    }
                }
            }

            if (bReqsMet)
            {
                Best[ALLIES_TEAM_INDEX] = DHMortarSpawnAreas[i];
            }
            else if (bSomeReqsMet && DHMortarSpawnAreas[i].TeamMustLoseAllRequired == SPN_Allies)
            {
                Best[ALLIES_TEAM_INDEX] = DHMortarSpawnAreas[i];
            }
        }
    }

    DHCurrentMortarSpawnArea[AXIS_TEAM_INDEX] = Best[AXIS_TEAM_INDEX];
    DHCurrentMortarSpawnArea[ALLIES_TEAM_INDEX] = Best[ALLIES_TEAM_INDEX];
}

function CheckTankCrewSpawnAreas()
{
    super.CheckTankCrewSpawnAreas();

    CheckMortarmanSpawnAreas();
}

function float RatePlayerStart(NavigationPoint N, byte Team, Controller Player)
{
    local PlayerStart P;
    local DH_RoleInfo DHRI;
    local float       Score, NextDist;
    local Controller  OtherPlayer;

    P = PlayerStart(N);

    if (P == none || Player == none)
    {
        return -10000000.0;
    }

    DHRI = DH_RoleInfo(DHPlayerReplicationInfo(Player.PlayerReplicationInfo).RoleInfo);

    if (LevelInfo.bUseSpawnAreas && CurrentSpawnArea[Team] != none)
    {
        if (CurrentTankCrewSpawnArea[Team]!= none && Player != none && DHRI.bCanBeTankCrew)
        {
            if (P.Tag != CurrentTankCrewSpawnArea[Team].Tag)
            {
                return -9000000.0;
            }
        }

        // Mortar spawn addition - Colin Basnett, 2010
        else if (DHCurrentMortarSpawnArea[Team] != none && Player != none && DHRI != none && DHRI.bCanUseMortars)
        {
            if (P.Tag != DHCurrentMortarSpawnArea[Team].Tag)
            {
                return -9000000.0;
            }
        }
        else
        {
            if (P.Tag != CurrentSpawnArea[Team].Tag)
            {
                return -9000000.0;
            }
        }
    }
    else if (Team != P.TeamNumber)
    {
        return -9000000.0;
    }

    P = PlayerStart(N);

    if (P == none || !P.bEnabled || P.PhysicsVolume.bWaterVolume)
    {
        return -10000000.0;
    }

    // Assess candidate
    if (P.bPrimaryStart)
    {
        Score = 10000000.0;
    }
    else
    {
        Score = 5000000.0;
    }

    if (N == LastStartSpot || N == LastPlayerStartSpot)
    {
        Score -= 10000.0;
    }
    else
    {
        Score += 3000.0 * FRand(); // randomize
    }

    for (OtherPlayer = Level.ControllerList; OtherPlayer != none; OtherPlayer = OtherPlayer.NextController)
    {
        if (OtherPlayer.bIsPlayer && (OtherPlayer.Pawn != none))
        {
            if (OtherPlayer.Pawn.Region.Zone == N.Region.Zone)
            {
                Score -= 1500.0;
            }

            NextDist = VSize(OtherPlayer.Pawn.Location - N.Location);

            if (NextDist < OtherPlayer.Pawn.CollisionRadius + OtherPlayer.Pawn.CollisionHeight)
            {
                Score -= 1000000.0;

            }
            else if (NextDist < 3000.0 && FastTrace(N.Location, OtherPlayer.Pawn.Location))
            {
                Score -= (10000.0 - NextDist);
            }
            else if (NumPlayers + NumBots == 2)
            {
                Score += 2.0 * VSize(OtherPlayer.Pawn.Location - N.Location);

                if (FastTrace(N.Location, OtherPlayer.Pawn.Location))
                {
                    Score -= 10000.0;
                }
            }
        }
    }

    return FMax(Score, 5.0);
}

// Spawns the bot and randomly gives them a role
function Bot SpawnBot(optional string botName)
{
    local DHBot          NewBot;
    local RosterEntry    Chosen;
    local UnrealTeamInfo BotTeam;
    local int            MyRole;
    local RORoleInfo     RI;

    BotTeam = GetBotTeam();
    Chosen = BotTeam.ChooseBotClass(botName);

    if (Chosen.PawnClass == none)
    {
        Chosen.Init();
    }

    // Change default bot class
    Chosen.PawnClass = class<Pawn>(DynamicLoadObject(DefaultPlayerClassName, class'class'));

    NewBot = DHBot(Spawn(Chosen.PawnClass.default.ControllerClass));


    if (NewBot != none)
    {
        InitializeBot(NewBot,BotTeam,Chosen);

        MyRole = GetDHBotNewRole(NewBot,BotTeam.TeamIndex);

        if (MyRole >= 0)
        {
            RI = GetRoleInfo(BotTeam.TeamIndex, MyRole);
        }

        if (MyRole == -1 || RI == none)
        {
            NewBot.Destroy();
            return none;
        }

        NewBot.CurrentRole = MyRole;
        NewBot.DesiredRole = MyRole;

        // Increment the RoleCounter for the new role
        if (BotTeam.TeamIndex == AXIS_TEAM_INDEX)
        {
            DHGameReplicationInfo(GameReplicationInfo).DHAxisRoleCount[NewBot.CurrentRole]++;
        }
        else if (BotTeam.TeamIndex == ALLIES_TEAM_INDEX)
        {
            DHGameReplicationInfo(GameReplicationInfo).DHAlliesRoleCount[NewBot.CurrentRole]++;
        }

        // Tone down the "gamey" bot parameters
        NewBot.Jumpiness = 0.0;
        NewBot.TranslocUse = 0.0;

        // Set the bots favorite weapon to thier primary weapon
        NewBot.FavoriteWeapon=class<ROWeapon>(RI.PrimaryWeapons[0].Item);

        // Tweak the bots abilities and characteristics based on their role
        switch (RI.PrimaryWeaponType)
        {
            case WT_SMG:
                NewBot.CombatStyle = 1.0 - (FRand() * 0.2);
                NewBot.Accuracy = 0.3;
                NewBot.StrafingAbility = 0.0;
                break;

            case WT_SemiAuto:
                NewBot.CombatStyle = 0.0;
                NewBot.Accuracy = 0.5;
                NewBot.StrafingAbility = -1.0;
                break;

            case WT_Rifle:
                NewBot.CombatStyle = -1.0 + (FRand() * 0.4);
                NewBot.Accuracy = 0.75;
                NewBot.StrafingAbility = -1.0;
                break;

            case WT_LMG:
                NewBot.CombatStyle = -1.0;
                NewBot.Accuracy = 0.75;
                NewBot.StrafingAbility = -1.0;
                break;

            case WT_Sniper:
                NewBot.CombatStyle = -1.0;
                NewBot.Accuracy = 1.0;
                NewBot.StrafingAbility = -1.0;
                break;
        }

        DHPlayerReplicationInfo(NewBot.PlayerReplicationInfo).RoleInfo = RI;
        ChangeWeapons(NewBot, -2, -2, -2);
        SetCharacter(NewBot);
    }

    return NewBot;
}

// Get a new random role for a bot - replaces old GetBotNewRole to use DHBots instead
// If a new role is successfully found the role number for that role will be returned (if a role cannot be found, returns -1)
function int GetDHBotNewRole(DHBot ThisBot, int BotTeamNum)
{
    local int MyRole, Count, AltRole;

    if (ThisBot != none)
    {
        MyRole = Rand(arraycount(DHAxisRoles));

        do
        {
            if (FRand() < LevelInfo.VehicleBotRoleBalance)
            {
                AltRole = GetVehicleRole(ThisBot.PlayerReplicationInfo.Team.TeamIndex, MyRole);

                if (AltRole != -1)
                {
                    MyRole = AltRole;
                    break;
                }
            }

            // Temp hack to prevent bots from getting MG roles
            if (RoleLimitReached(ThisBot.PlayerReplicationInfo.Team.TeamIndex, MyRole) || (GetRoleInfo(BotTeamNum, MyRole).PrimaryWeaponType == WT_LMG) ||
                (GetRoleInfo(BotTeamNum, MyRole).PrimaryWeaponType == WT_PTRD))
            {
                Count++;

                if (Count > 10)
                {
                    Log("DarkestHourGame: Unable to find a suitable role in SpawnBot()");

                    return -1;
                }
                else
                {
                    MyRole++;

                    if ((BotTeamNum == 0 && MyRole >= arraycount(DHAxisRoles)) || (BotTeamNum == 1 && MyRole >= arraycount(DHAxisRoles)))
                    {
                        MyRole = 0;
                    }
                }
            }
            else
            {
                break;
            }
        }

        return MyRole;
    }

    return -1;
}

// Give player points for destroying an enemy vehicle
function ScoreVehicleKill(Controller Killer, ROVehicle Vehicle, float Points)
{
    if (Killer == none || Points <= 0 || Killer.PlayerReplicationInfo == none || Killer.GetTeamNum() == Vehicle.GetTeamNum())
    {
        return;
    }

    Killer.PlayerReplicationInfo.Score += Points;

    ScoreEvent(Killer.PlayerReplicationInfo, Points, "Vehicle_kill");
}

// Give player a point for resupplying an MG gunner
function ScoreMGResupply(Controller Dropper, Controller Gunner)
{
    local int ResupplyAward;

    if (Dropper == Gunner)
    {
        return;
    }
    else if (DHPlayerReplicationInfo(Dropper.PlayerReplicationInfo) != none && DHPlayerReplicationInfo(Dropper.PlayerReplicationInfo).RoleInfo != none)
    {
        ResupplyAward = 5;
        Dropper.PlayerReplicationInfo.Score += ResupplyAward;

        ScoreEvent(Dropper.PlayerReplicationInfo, ResupplyAward, "MG_resupply");
    }
}

// Give player a point for resupplying an AT gunner
function ScoreATResupply(Controller Dropper, Controller Gunner)
{
    local int ResupplyAward;

    if (Dropper == Gunner)
    {
        return;
    }
    else if (DHPlayerReplicationInfo(Dropper.PlayerReplicationInfo) != none && DHPlayerReplicationInfo(Dropper.PlayerReplicationInfo).RoleInfo != none)
    {
        ResupplyAward = 2;
        Dropper.PlayerReplicationInfo.Score += ResupplyAward;

        ScoreEvent(Dropper.PlayerReplicationInfo, ResupplyAward, "AT_resupply");
    }
}

// Give player a point for loading an AT gunner
function ScoreATReload(Controller Loader, Controller Gunner)
{
    local int LoadAward;

    if (Loader == Gunner)
    {
        return;
    }
    else if (DHPlayerReplicationInfo(Loader.PlayerReplicationInfo) != none && DHPlayerReplicationInfo(Loader.PlayerReplicationInfo).RoleInfo != none)
    {
        LoadAward = 1;
        Loader.PlayerReplicationInfo.Score += LoadAward;

        ScoreEvent(Loader.PlayerReplicationInfo, LoadAward, "AT_reload");
    }
}

// Give player a point for resupplying an MG gunner
function ScoreRadioUsed(Controller Radioman)
{
    local int RadioUsedAward;

    if (DHPlayerReplicationInfo(Radioman.PlayerReplicationInfo) != none && DHPlayerReplicationInfo(Radioman.PlayerReplicationInfo).RoleInfo != none)
    {
        RadioUsedAward = 5;
        Radioman.PlayerReplicationInfo.Score += RadioUsedAward;

        ScoreEvent(Radioman.PlayerReplicationInfo, RadioUsedAward, "Radioman_used");
    }
}

// Give player two points for resupplying a mortar operator
function ScoreMortarResupply(Controller Dropper, Controller Gunner)
{
    local int ResupplyAward;

    if (Dropper == none || Dropper == Gunner || Dropper.PlayerReplicationInfo == none)
    {
        return;
    }

    Dropper.PlayerReplicationInfo.Score += 2;
    ScoreEvent(Dropper.PlayerReplicationInfo, ResupplyAward, "Mortar_resupply");
}

// Give spotter a point or two for spotting a kill
function ScoreMortarSpotAssist(Controller Spotter, Controller Mortarman)
{
    if (Spotter == none || Spotter == Mortarman || Spotter.PlayerReplicationInfo == none || Mortarman == none || Mortarman.PlayerReplicationInfo == none)
    {
        return;
    }

    Spotter.PlayerReplicationInfo.Score += 2;
    Mortarman.PlayerReplicationInfo.Score += 1;
}

// Handles reduction or elimination of damage
function int ReduceDamage(int Damage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
    // Check if the player has just used a select-a-spawn teleport and should be protected from damage
    if (InstigatedBy != none &&
        Injured != none &&
        InstigatedBy != Injured &&
        Injured.PlayerReplicationInfo != none &&
        DH_Pawn(Injured) != none &&
        DH_Pawn(Injured).TeleSpawnProtected())
    {
        return 0;
    }
    else
    {
        return super.ReduceDamage(Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
    }
}

// Stop the game from automatically trimming longer names
event PlayerController Login(string Portal, string Options, out string Error)
{
    local string           InName;
    local PlayerController NewPlayer;

    InName = Left(ParseOption (Options, "Name"), 32);

    NewPlayer = super.Login(Portal, Options, Error);

    ChangeName(NewPlayer, InName, false);

    return NewPlayer;
}

// Overridden to increase max name length from 20 to 32 chars
function ChangeName(Controller Other, string S, bool bNameChange)
{
    local Controller APlayer, C, P;

    if (S == "")
    {
        return;
    }

    S = StripColor(S); // strip out color codes

    if (Other.PlayerReplicationInfo.PlayerName ~= S)
    {
        return;
    }

    S = Left(S, 32);
    ReplaceText(S, "\"", "");

    if (bEpicNames && Bot(Other) != none)
    {
        if (TotalEpic < 21)
        {
            S = EpicNames[EpicOffset % 21];
            EpicOffset++;
            TotalEpic++;
        }
        else
        {
            S = NamePrefixes[NameNumber%10] $ "CliffyB" $ NameSuffixes[NameNumber % 10];
            NameNumber++;
        }
    }

    for (APlayer = Level.ControllerList; APlayer != none; APlayer = APlayer.NextController)
    {
        if (APlayer.bIsPlayer && APlayer.PlayerReplicationInfo.PlayerName ~= S)
        {
            if (Other.IsA('PlayerController'))
            {
                PlayerController(Other).ReceiveLocalizedMessage(GameMessageClass, 8);

                return;
            }
            else
            {
                if (Other.PlayerReplicationInfo.bIsFemale)
                {
                    S = FemaleBackupNames[FemaleBackupNameOffset % 32];
                    FemaleBackupNameOffset++;
                }
                else
                {
                    S = MaleBackupNames[MaleBackupNameOffset % 32];
                    MaleBackupNameOffset++;
                }

                for (P = Level.ControllerList; P != none; P = P.NextController)
                {
                    if (P.bIsPlayer && P.PlayerReplicationInfo.PlayerName ~= S)
                    {
                        S = NamePrefixes[NameNumber % 10] $ S $ NameSuffixes[NameNumber % 10];
                        NameNumber++;
                        break;
                    }
                }

                break;
            }

            S = NamePrefixes[NameNumber % 10] $ S $ NameSuffixes[NameNumber % 10];
            NameNumber++;
            break;
        }
    }

    if (bNameChange)
    {
        GameEvent("NameChange", S, Other.PlayerReplicationInfo);
    }

    if (S ~= "CliffyB")
    {
        bEpicNames = true;
    }

    Other.PlayerReplicationInfo.SetPlayerName(S);

    // Notify local players
    if  (bNameChange)
    {
        for (C = Level.ControllerList; C != none; C = C.NextController)
        {
            if (PlayerController(C) != none && Viewport(PlayerController(C).Player) != none)
            {
                PlayerController(C).ReceiveLocalizedMessage(class'GameMessage', 2, Other.PlayerReplicationInfo);
            }
        }
    }
}

function BroadcastLastObjectiveMessage(int Team_that_is_about_to_win)
{
    BroadcastLocalizedMessage(class'DHLastObjectiveMsg', Team_that_is_about_to_win);
}

function AddDefaultInventory(Pawn aPawn)
{
    if (DH_Pawn(aPawn) != none)
    {
        DH_Pawn(aPawn).AddDefaultInventory();
    }

    SetPlayerDefaults(aPawn);
}

//The following is a clusterfuck of hacky overriding of RO's arbitrarily low limit of roles from 10 to 16
function AddRole(RORoleInfo NewRole)
{
    local DHGameReplicationInfo DHGRI;
    local DH_RoleInfo           DHRI;

    DHGRI = DHGameReplicationInfo(GameReplicationInfo);
    DHRI = DH_RoleInfo(NewRole);

    if (NewRole.Side == SIDE_Allies)
    {
        if (AlliesRoleIndex >= arraycount(DHAlliesRoles))
        {
            Warn(NewRole @ "ignored when adding Allied roles to the map, exceeded limit");
            return;
        }

        DHAlliesRoles[AlliesRoleIndex] = DHRI;
        DHGRI.DHAlliesRoles[AlliesRoleIndex] = DHRI;
        AlliesRoleIndex++;
    }
    else
    {
        if (AxisRoleIndex >= arraycount(DHAxisRoles))
        {
            Warn(NewRole @ "ignored when adding Axis roles to the map, exceeded limit");
            return;
        }

        DHAxisRoles[AxisRoleIndex] = DHRI;
        DHGRI.DHAxisRoles[AxisRoleIndex] = DHRI;
        AxisRoleIndex++;
    }
}

function RORoleInfo GetRoleInfo(int Team, int Num)
{
    if (Team > 1 || Num < 0 || Num >= arraycount(DHAxisRoles))
    {
        return none;
    }

    if (Team == AXIS_TEAM_INDEX)
    {
        return DHAxisRoles[Num];
    }
    else if (Team == ALLIES_TEAM_INDEX)
    {
        return DHAlliesRoles[Num];
    }

    return none;
}

function bool RoleLimitReached(int Team, int Num)
{
    local DHGameReplicationInfo DHGRI;

    // This shouldn't even happen, but if it does, just say the limit was reached
    if (Team > 1 || Num < 0 || (Team == AXIS_TEAM_INDEX && DHAxisRoles[Num] == none) || (Team == ALLIES_TEAM_INDEX && DHAlliesRoles[Num] == none) || Num >= arraycount(DHAxisRoles))
    {
        return true;
    }

    DHGRI = DHGameReplicationInfo(GameReplicationInfo);

    if (Team == AXIS_TEAM_INDEX && DHAxisRoles[Num].GetLimit(DHGRI.MaxPlayers) != 0 && DHGRI.DHAxisRoleCount[Num] >= DHAxisRoles[Num].GetLimit(DHGRI.MaxPlayers))
    {
        return true;
    }
    else if (Team == ALLIES_TEAM_INDEX && DHAlliesRoles[Num].GetLimit(DHGRI.MaxPlayers) != 0 && DHGRI.DHAlliesRoleCount[Num] >= DHAlliesRoles[Num].GetLimit(DHGRI.MaxPlayers))
    {
        return true;
    }

    return false;
}

function bool HumanWantsRole(int Team, int Num)
{
    local Controller            C;
    local ROBot                 BotHasRole;
    local DHGameReplicationInfo DHGRI;

    // This shouldn't even happen, but if it does, just say the limit was reached
    if (Team > 1 || Num < 0 || (Team == AXIS_TEAM_INDEX && DHAxisRoles[Num] == none) || (Team == ALLIES_TEAM_INDEX && DHAlliesRoles[Num] == none) || Num >= arraycount(DHAxisRoles))
    {
        return false;
    }

    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        if (C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none && C.PlayerReplicationInfo.Team.TeamIndex == Team)
        {
            if (ROBot(C) != none && ROBot(C).CurrentRole == Num)
            {
                BotHasRole = ROBot(C);
                break;
            }
        }
    }

    DHGRI = DHGameReplicationInfo(GameReplicationInfo);

    if (BotHasRole != none)
    {
        BotHasRole.Destroy();

        if (Team == AXIS_TEAM_INDEX)
        {
            DHGRI.DHAxisRoleCount[Num] --;
            DHGRI.DHAxisRoleBotCount[Num] --;
        }
        else if (Team == ALLIES_TEAM_INDEX)
        {
            DHGRI.DHAlliesRoleCount[Num] --;
            DHGRI.DHAlliesRoleBotCount[Num] --;
        }

        return true;
    }

    return false;
}

function int GetVehicleRole(int Team, int Num)
{
    local int i;

    // This shouldn't even happen, but if it does, just say the limit was reached
    if (Team > 1 || Num < 0 || (Team == AXIS_TEAM_INDEX && DHAxisRoles[Num] == none) || (Team == ALLIES_TEAM_INDEX && DHAlliesRoles[Num] == none) || Num >= arraycount(DHAxisRoles))
    {
        return -1;
    }

    // Should probably do this team specific in case the teams have different amounts of roles
    for (i = 0; i < arraycount(DHAxisRoles); ++i)
    {
        if (GetRoleInfo(Team, i) != none && GetRoleInfo(Team, i).bCanBeTankCrew && !RoleLimitReached(Team, i))
        {
            return i;
        }
    }

    return -1;
}

function int GetBotNewRole(ROBot ThisBot, int BotTeamNum)
{
    local int MyRole, Count, AltRole;

    if (ThisBot != none)
    {
        MyRole = Rand(arraycount(DHAxisRoles));

        do
        {
            if (FRand() < LevelInfo.VehicleBotRoleBalance)
            {
                AltRole = GetVehicleRole(ThisBot.PlayerReplicationInfo.Team.TeamIndex, MyRole);

                if (AltRole != -1)
                {
                    MyRole = AltRole;
                    break;
                }
            }

            // Temp hack to prevent bots from getting MG roles
            if (RoleLimitReached(ThisBot.PlayerReplicationInfo.Team.TeamIndex, MyRole) || GetRoleInfo(BotTeamNum, MyRole).PrimaryWeaponType == WT_LMG
                || GetRoleInfo(BotTeamNum, MyRole).PrimaryWeaponType == WT_PTRD)
            {
                Count++;

                if (Count > arraycount(DHAxisRoles))
                {
                    Log("ROTeamGame: Unable to find a suitable role in SpawnBot()");

                    return -1;
                }
                else
                {
                    MyRole++;

                    if (MyRole >= arraycount(DHAxisRoles))
                    {
                        MyRole = 0;
                    }
                }
            }
            else
            {
                break;
            }
        }

        return MyRole;
    }

    return -1;
}

function UpdateRoleCounts()
{
    local Controller C;
    local int i;
    local DHGameReplicationInfo DHGRI;

    DHGRI = DHGameReplicationInfo(GameReplicationInfo);

    for (i = 0; i < arraycount(DHAxisRoles); ++i)
    {
        if (DHAxisRoles[i] != none)
        {
            DHGRI.DHAxisRoleCount[i] = 0;
            DHGRI.DHAxisRoleBotCount[i] = 0;
        }
    }

    for (i = 0; i < arraycount(DHAlliesRoles); ++i)
    {
        if (DHAlliesRoles[i] != none)
        {
            DHGRI.DHAlliesRoleCount[i] = 0;
            DHGRI.DHAlliesRoleBotCount[i] = 0;
        }
    }

    for (C = Level.ControllerList; C != none; C = C.NextController)
    {
        if (C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.Team != none)
        {
            if (ROPlayer(C) != none && ROPlayer(C).CurrentRole != -1)
            {
                if (C.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX)
                {
                    DHGRI.DHAlliesRoleCount[ROPlayer(C).CurrentRole]++;
                }
                else if (C.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX)
                {
                    DHGRI.DHAxisRoleCount[ROPlayer(C).CurrentRole]++;
                }
            }
            else if (ROBot(C) != none && ROBot(C).CurrentRole != -1)
            {
                if (C.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX)
                {
                    DHGRI.DHAlliesRoleCount[ROBot(C).CurrentRole]++;
                    DHGRI.DHAlliesRoleBotCount[ROBot(C).CurrentRole]++;
                }
                else if (C.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX)
                {
                    DHGRI.DHAxisRoleCount[ROBot(C).CurrentRole]++;
                    DHGRI.DHAxisRoleBotCount[ROBot(C).CurrentRole]++;
                }
            }
        }
    }
}

function ChangeRole(Controller aPlayer, int i, optional bool bForceMenu)
{
    local RORoleInfo RI;
    local ROPlayer   Playa;
    local ROBot      MrRoboto;

    if (aPlayer == none || !aPlayer.bIsPlayer || aPlayer.PlayerReplicationInfo.Team == none || aPlayer.PlayerReplicationInfo.Team.TeamIndex > 1)
    {
        return;
    }

    RI = GetRoleInfo(aPlayer.PlayerReplicationInfo.Team.TeamIndex, i);

    if (RI == none)
    {
        return;
    }

    // Lets try and avoid 50 casts - Ramm
    Playa = ROPlayer(aPlayer);

    if (Playa == none)
    {
        MrRoboto = ROBot(aPlayer);
    }


    if (Playa != none)
    {
        Playa.DesiredRole = i;

        if (aPlayer.Pawn == none)
        {
            // Try and kick a bot out of this role if bots are occupying it
            if (RoleLimitReached(aPlayer.PlayerReplicationInfo.Team.TeamIndex, i))
            {
                HumanWantsRole(aPlayer.PlayerReplicationInfo.Team.TeamIndex, i);
            }

            if (!RoleLimitReached(aPlayer.PlayerReplicationInfo.Team.TeamIndex, i))
            {
                if (bForceMenu)
                {
                    Playa.ClientReplaceMenu("ROInterface.ROUT2K4PlayerSetupPage", false, "Weapons");
                }
                else
                {
                    // Decrement the RoleCounter for the old role
                    if (Playa.CurrentRole != -1)
                    {
                        if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX)
                        {
                            DHGameReplicationInfo(GameReplicationInfo).DHAxisRoleCount[Playa.CurrentRole]--;
                        }
                        else if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX)
                        {
                            DHGameReplicationInfo(GameReplicationInfo).DHAlliesRoleCount[Playa.CurrentRole]--;
                        }
                    }

                    Playa.CurrentRole = i;

                    // Increment the RoleCounter for the new role
                    if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX)
                    {
                        DHGameReplicationInfo(GameReplicationInfo).DHAxisRoleCount[Playa.CurrentRole]++;
                    }
                    else if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX)
                    {
                        DHGameReplicationInfo(GameReplicationInfo).DHAlliesRoleCount[Playa.CurrentRole]++;
                    }

                    ROPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).RoleInfo = RI;
                    Playa.PrimaryWeapon = -1;
                    Playa.SecondaryWeapon = -1;
                    Playa.GrenadeWeapon = -1;
                    Playa.bWeaponsSelected = false;
                    SetCharacter(aPlayer);
                }
            }
            else
            {
                Playa.DesiredRole = Playa.CurrentRole;
                PlayerController(aPlayer).ReceiveLocalizedMessage(GameMessageClass, 17, none, none, RI);
            }

            // Since we're changing roles, clear all associated requests/rally points
            ClearSavedRequestsAndRallyPoints(Playa, false);
        }
        else
        {
            PlayerController(aPlayer).ReceiveLocalizedMessage(GameMessageClass, 16, none, none, RI);
        }
    }
    else if (MrRoboto != none)
    {
        if (MrRoboto.CurrentRole == i)
        {
            return;
        }

        MrRoboto.DesiredRole = i;

        if (aPlayer.Pawn == none)
        {
            if (!RoleLimitReached(aPlayer.PlayerReplicationInfo.Team.TeamIndex, i))
            {
                // Decrement the RoleCounter for the old role
                if (MrRoboto.CurrentRole != -1)
                {
                    if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX)
                    {
                        DHGameReplicationInfo(GameReplicationInfo).DHAxisRoleCount[MrRoboto.CurrentRole]--;
                    }
                    else if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX)
                    {
                        DHGameReplicationInfo(GameReplicationInfo).DHAlliesRoleCount[MrRoboto.CurrentRole]--;
                    }
                }

                MrRoboto.CurrentRole = i;

                // Increment the RoleCounter for the new role
                if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX)
                {
                    DHGameReplicationInfo(GameReplicationInfo).DHAxisRoleCount[MrRoboto.CurrentRole]++;
                }
                else if (aPlayer.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX)
                {
                    DHGameReplicationInfo(GameReplicationInfo).DHAlliesRoleCount[MrRoboto.CurrentRole]++;
                }

                ROPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).RoleInfo = RI;
                SetCharacter(aPlayer);
            }
            else
            {
                MrRoboto.DesiredRole = ROBot(aPlayer).CurrentRole;
            }
        }
    }
}

function Killed(Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> DamageType)
{
    // Removes console spam whenever you kill an empty tank
    if (Killed != none)
    {
        super.Killed(Killer, Killed, KilledPawn, DamageType);
    }
}

function bool RoleExists(byte TeamID, DH_RoleInfo RI)
{
    local int i;

    if (TeamID == 0)
    {
        for (i = 0; i < arraycount(DHAxisRoles); ++i)
        {
            if (DHAxisRoles[i] == RI)
            {
                return true;
            }
        }
    }
    else if (TeamID == 1)
    {
        for (i = 0; i < arraycount(DHAlliesRoles); ++i)
        {
            if (DHAlliesRoles[i] == RI)
            {
                return true;
            }
        }
    }

    return false;
}

state RoundInPlay
{
    function BeginState()
    {
        local Controller P, NextC;
        local Actor A;
        local int i;
        local ROGameReplicationInfo GRI;
        local ROVehicleFactory ROV;

        // Reset all round properties
        RoundStartTime = ElapsedTime;
        GRI = ROGameReplicationInfo(GameReplicationInfo);
        GRI.RoundStartTime = RoundStartTime;

        SpawnCount[AXIS_TEAM_INDEX] = 0;
        SpawnCount[ALLIES_TEAM_INDEX] = 0;

        LastReinforcementTime[AXIS_TEAM_INDEX] = ElapsedTime;
        LastReinforcementTime[ALLIES_TEAM_INDEX] = ElapsedTime;
        GRI.LastReinforcementTime[AXIS_TEAM_INDEX] = LastReinforcementTime[AXIS_TEAM_INDEX];
        GRI.LastReinforcementTime[ALLIES_TEAM_INDEX] = LastReinforcementTime[ALLIES_TEAM_INDEX];

        // Arty
        GRI.bArtilleryAvailable[AXIS_TEAM_INDEX] = 0;
        GRI.bArtilleryAvailable[ALLIES_TEAM_INDEX] = 0;
        GRI.LastArtyStrikeTime[AXIS_TEAM_INDEX] = ElapsedTime - LevelInfo.GetStrikeInterval(AXIS_TEAM_INDEX);
        GRI.LastArtyStrikeTime[ALLIES_TEAM_INDEX] = ElapsedTime - LevelInfo.GetStrikeInterval(ALLIES_TEAM_INDEX);
        GRI.TotalStrikes[AXIS_TEAM_INDEX] = 0;
        GRI.TotalStrikes[ALLIES_TEAM_INDEX] = 0;
        for (i = 0; i < arraycount(GRI.AxisRallyPoints); ++i)
        {
            GRI.AlliedRallyPoints[i].OfficerPRI = none;
            GRI.AlliedRallyPoints[i].RallyPointLocation = vect(0,0,0);
            GRI.AxisRallyPoints[i].OfficerPRI = none;
            GRI.AxisRallyPoints[i].RallyPointLocation = vect(0,0,0);
        }

        // Clear help requests
        for (i = 0; i < arraycount(GRI.AxisHelpRequests); ++i)
        {
            GRI.AlliedHelpRequests[i].OfficerPRI = none;
            GRI.AlliedHelpRequests[i].requestType = 255;
            GRI.AxisHelpRequests[i].OfficerPRI = none;
            GRI.AxisHelpRequests[i].requestType = 255;
        }

        // Just in case the limit is set to a ridiculously low value, handle it right
        if (!SpawnLimitReached(AXIS_TEAM_INDEX))
        {
            GRI.bReinforcementsComing[AXIS_TEAM_INDEX] = 1;
            GRI.SpawnCount[AXIS_TEAM_INDEX] = 100;
        }
        if (!SpawnLimitReached(ALLIES_TEAM_INDEX))
        {
            GRI.bReinforcementsComing[ALLIES_TEAM_INDEX] = 1;
            GRI.SpawnCount[ALLIES_TEAM_INDEX] = 100;
        }

        // Reset all controllers
        P = Level.ControllerList;
        while (P != none)
        {
            NextC = P.NextController;

            if (P.PlayerReplicationInfo == none || !P.PlayerReplicationInfo.bOnlySpectator)
            {
                if (PlayerController(P) != none)
                    PlayerController(P).ClientReset();
                P.Reset();
            }

            P = NextC;
        }

        // Reset ALL actors (except controllers and ROVehicleFactorys)
        foreach AllActors(class'Actor', A)
        {
            if (!A.IsA('Controller') && !A.IsA('ROVehicleFactory'))
                A.Reset();
        }

        // Reset ALL ROVehicleFactorys - must reset these after vehicles, otherwise the vehicles that get spawned by the vehicle factories get destroyed instantly as they are reset
        foreach AllActors(class'ROVehicleFactory', ROV)
        {
            ROV.Reset();
        }

        // Use the starting spawns
        if (LevelInfo.bUseSpawnAreas)
        {
            CheckSpawnAreas();
            CheckTankCrewSpawnAreas();
            CheckVehicleFactories();
            CheckResupplyVolumes();
            CheckMineVolumes();
        }

        // Make the bots find objectives when the round starts
        FindNewObjectives(None);

        // Notify players that the map has been updated
        NotifyPlayersOfMapInfoChange(NEUTRAL_TEAM_INDEX, none, true);

        ResetMortarTargets();

        DHGameReplicationInfo(GameReplicationInfo).DHSpawnCount[ALLIES_TEAM_INDEX] = LevelInfo.Allies.SpawnLimit;
        DHGameReplicationInfo(GameReplicationInfo).DHSpawnCount[AXIS_TEAM_INDEX] = LevelInfo.Axis.SpawnLimit;
    }

    function EndRound(int Winner)
    {
        local string MapName;
        local int    i, j;
        local bool   bMatchOver, bRussianSquadLeader;

        switch (Winner)
        {
            case AXIS_TEAM_INDEX:
                Teams[AXIS_TEAM_INDEX].Score += 1.0;
                BroadcastLocalizedMessage(class'DHRoundOverMsg', 0,,, DHLevelInfo);
                TeamScoreEvent(AXIS_TEAM_INDEX, 1, "team_victory");
                break;

            case ALLIES_TEAM_INDEX:
                Teams[ALLIES_TEAM_INDEX].Score += 1.0;
                BroadcastLocalizedMessage(class'DHRoundOverMsg', 1,,, DHLevelInfo);
                TeamScoreEvent(ALLIES_TEAM_INDEX, 1, "team_victory");
                break;

            default:
                BroadcastLocalizedMessage(class'RORoundOverMsg', 2);
                break;
        }

        RoundCount++;

        // Used for Steam Stats below
        bMatchOver = true;

        if (RoundLimit != 0 && RoundCount >= RoundLimit)
        {
            EndGame(none, "RoundLimit");
        }
        else if (WinLimit != 0 && (Teams[AXIS_TEAM_INDEX].Score >= WinLimit || Teams[ALLIES_TEAM_INDEX].Score >= WinLimit))
        {
            EndGame(none, "WinLimit");
        }
        else
        {
            bMatchOver = false;
            GotoState('RoundOver');
        }

        // Get the MapName out of the URL
        MapName = Level.GetLocalURL();
        i = InStr(MapName, "/");

        if (i < 0)
        {
            i = 0;
        }

        j = InStr(MapName, "?");

        if (j < 0)
        {
            j = Len(MapName);
        }

        if (Mid(MapName, j - 3, 3) ~= "rom")
        {
            j -= 5;
        }

        MapName = Mid(MapName, i + 1, j - i);

        // Set the map as won in the Steam Stats of everyone on the winning team
        for (i = 0; i < GameReplicationInfo.PRIArray.Length; ++i)
        {
            if (ROSteamStatsAndAchievements(GameReplicationInfo.PRIArray[i].SteamStatsAndAchievements) != none)
            {
                if (GameReplicationInfo.PRIArray[i].Team != none && GameReplicationInfo.PRIArray[i].Team.TeamIndex == Winner)
                {
                    if (bMatchOver)
                    {
                        if (GameReplicationInfo.PRIArray[i].Team.TeamIndex == ALLIES_TEAM_INDEX && ROPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]) != none)
                        {
                            bRussianSquadLeader = ROPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).RoleInfo.bIsLeader &&
                                !ROPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]).RoleInfo.bCanBeTankCrew;
                        }
                        else
                        {
                            bRussianSquadLeader = false;
                        }

                        // NOTE: This MUST be called before ROSteamStatsAndAchievements.MatchEnded()
                        ROSteamStatsAndAchievements(GameReplicationInfo.PRIArray[i].SteamStatsAndAchievements).WonMatch(MapName, Winner, bRussianSquadLeader);
                    }
                    else
                    {
                        // NOTE: This MUST be called before ROSteamStatsAndAchievements.MatchEnded()
                        ROSteamStatsAndAchievements(GameReplicationInfo.PRIArray[i].SteamStatsAndAchievements).WonRound();
                    }
                }

                ROSteamStatsAndAchievements(GameReplicationInfo.PRIArray[i].SteamStatsAndAchievements).MatchEnded();
            }
        }
    }

    function Timer()
    {
        local int i, ArtilleryStrikeInt;
        local ROGameReplicationInfo GRI;

        global.Timer();

        GRI = ROGameReplicationInfo(GameReplicationInfo);

        if (NeedPlayers() && AddBot() && (RemainingBots > 0))
            RemainingBots--;

        // Go through both teams and update artillery availability
        for (i = 0; i < 2; ++i)
        {
            ArtilleryStrikeInt = LevelInfo.GetStrikeInterval(i);

            if ((GRI.TotalStrikes[i] < GRI.ArtilleryStrikeLimit[i]) && ElapsedTime > GRI.LastArtyStrikeTime[i] + ArtilleryStrikeInt)
            {
                    GRI.bArtilleryAvailable[i] = 1;
            }
            else
            {
                    GRI.bArtilleryAvailable[i] = 0;
            }
        }

        // If round time is up, the defending team wins, if any
        if (ElapsedTime > RoundStartTime + RoundDuration)
        {
            if (LevelInfo.DefendingSide == SIDE_Axis)
                EndRound(AXIS_TEAM_INDEX);
            else if (LevelInfo.DefendingSide == SIDE_Allies)
                EndRound(ALLIES_TEAM_INDEX);
            else
                ChooseWinner();
        }
    }

    function EndState()
    {
        local Pawn P;

        super.EndState();

        foreach DynamicActors(class'Pawn', P)
        {
            P.StopWeaponFiring();
        }
    }
}

state ResetGameCountdown
{
    // Matt: modified to replace ROArtillerySpawner with DH_ArtillerySpawner
    function BeginState()
    {
        local DH_ArtillerySpawner AS;

        RoundStartTime = ElapsedTime + 10.0;

        ROGameReplicationInfo(GameReplicationInfo).bReinforcementsComing[AXIS_TEAM_INDEX] = 0;
        ROGameReplicationInfo(GameReplicationInfo).bReinforcementsComing[ALLIES_TEAM_INDEX] = 0;

        // Destroy any artillery spawners so they don't keep calling airstrikes.
        foreach DynamicActors(class'DH_ArtillerySpawner', AS)
        {
            AS.Destroy();
        }

        Level.Game.BroadcastLocalized(none, class'ROResetGameMsg', 10);
    }

    // Matt: modified to spawn a DH_ClientResetGame actor on a server, which replicates to net clients to remove any temporary client-only actors, e.g. smoke effects
    function Timer()
    {
        global.Timer();

        if (ElapsedTime > RoundStartTime - 1.0) // the -1.0 gets rid of "The game will restart in 0 seconds"
        {
            if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
            {
                Spawn(class'DH_ClientResetGame');
            }

            Level.Game.BroadcastLocalized(none, class'ROResetGameMsg', 11);
            ResetScores();
            GotoState('RoundInPlay');
        }
        else
        {
            Level.Game.BroadcastLocalized(none, class'ROResetGameMsg', RoundStartTime - ElapsedTime);
        }
    }
}

// Wait period before a new round begins
// Matt: modified to replace ROArtillerySpawner with DH_ArtillerySpawner
state RoundOver
{
    function BeginState()
    {
        local DH_ArtillerySpawner AS;

        RoundStartTime = ElapsedTime;
        ROGameReplicationInfo(GameReplicationInfo).bReinforcementsComing[AXIS_TEAM_INDEX] = 0;
        ROGameReplicationInfo(GameReplicationInfo).bReinforcementsComing[ALLIES_TEAM_INDEX] = 0;

        // Destroy any artillery spawners so they don't keep calling airstrikes
        foreach DynamicActors(class'DH_ArtillerySpawner', AS)
        {
            AS.Destroy();
        }

    }
}

function ResetMortarTargets()
{
    local int k;
    local DHGameReplicationInfo GRI;

    if (GameReplicationInfo == none)
    {
        return;
    }

    GRI = DHGameReplicationInfo(GameReplicationInfo);

    if (GRI == none)
    {
        return;
    }

    // Clear mortar allied targets
    for (k = 0; k < arraycount(GRI.AlliedMortarTargets); ++k)
    {
        GRI.AlliedMortarTargets[k].Location = vect(0.0, 0.0, 0.0);
        GRI.AlliedMortarTargets[k].HitLocation = vect(0.0, 0.0, 0.0);
        GRI.AlliedMortarTargets[k].Controller = none;
        GRI.AlliedMortarTargets[k].Time = 0;
    }

    // Clear mortar german targets
    for (k = 0; k < arraycount(GRI.GermanMortarTargets); ++k)
    {
        GRI.GermanMortarTargets[k].Location = vect(0.0, 0.0, 0.0);
        GRI.GermanMortarTargets[k].HitLocation = vect(0.0, 0.0, 0.0);
        GRI.GermanMortarTargets[k].Controller = none;
        GRI.GermanMortarTargets[k].Time = 0;
    }
}

// Handle reinforcment checks and balances
function HandleReinforcements(Controller C)
{
    local DHPlayer DHP;

    DHP = DHPlayer(C);

    // Don't subtract / calc reinforcements as the player didn't get a pawn
    if (DHP == none && DHP.Pawn == none)
    {
        return;
    }

    //TODO: look into improving or rewriting this, as this is garbage looking
    if (DHP.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX && LevelInfo.Allies.SpawnLimit > 0)
    {
        DHGameReplicationInfo(GameReplicationInfo).DHSpawnCount[ALLIES_TEAM_INDEX] = LevelInfo.Allies.SpawnLimit - ++SpawnCount[ALLIES_TEAM_INDEX];

        // If the Allies have used up 85% of their reinforcements, send them a reinforcements low message
        if (SpawnCount[ALLIES_TEAM_INDEX] == Int(LevelInfo.Allies.SpawnLimit * 0.85))
        {
            SendReinforcementMessage(ALLIES_TEAM_INDEX, 0);
        }
    }
    else if (DHP.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX && LevelInfo.Axis.SpawnLimit > 0)
    {
        DHGameReplicationInfo(GameReplicationInfo).DHSpawnCount[AXIS_TEAM_INDEX] = LevelInfo.Axis.SpawnLimit - ++SpawnCount[AXIS_TEAM_INDEX];

        // If Axis has used up 85% of their reinforcements, send them a reinforcements low message
        if (SpawnCount[AXIS_TEAM_INDEX] == Int(LevelInfo.Axis.SpawnLimit * 0.85))
        {
            SendReinforcementMessage(AXIS_TEAM_INDEX, 0);
        }
    }

    if (DHP.bFirstRoleAndTeamChange && GetStateName() == 'RoundInPlay')
    {
        DHP.NotifyOfMapInfoChange();
        DHP.bFirstRoleAndTeamChange = true;
    }
}

// This function adds functionality so when you type "%r" in teamsay it'll output helpful debug info for reporting bugs in MP (returns mapname & coordinates)
static function string ParseChatPercVar(Mutator BaseMutator, Controller Who, string Cmd)
{
    local string Str;
    local string MapName;

    if (Who.Pawn == none)
    {
        return Cmd;
    }

    // Coordinates
    if (cmd ~= "%r")
    {
        // Get the level name string
        MapName = string(Who.Outer);

        if (MapName == "")
        {
            MapName = "Error No MapName";
        }

        // Finish parsing the string
        Str = "Map:" @ MapName @ "Coord:" @ string(Who.Pawn.Location) @ "Report: ";

        return Str;
    }

    return super.ParseChatPercVar(BaseMutator, Who,Cmd);
}

// Debug function for winning a round (needs admin or local)
exec function DebugWinGame(optional int TeamToWin)
{
    EndRound(TeamToWin);
}

function DeployRestartPlayer(Controller C, optional bool bHandleReinforcements, optional bool bUseOldRestart)
{
    if (bUseOldRestart || DHLevelInfo.SpawnMode == ESM_RedOrchestra)
    {
        SetCharacter(C);
        super(TeamGame).RestartPlayer(C);

        if (bHandleReinforcements)
        {
            HandleReinforcements(C);
        }
    }
    else
    {
        DHRestartPlayer(C, bHandleReinforcements); // This will handle reinforcements
    }
}

function DHRestartPlayer(Controller C, optional bool bHandleReinforcements)
{
    local TeamInfo BotTeam, OtherTeam;
    local DHPlayer DHC;
    local byte     SpawnError;

    DHC = DHPlayer(C);

    if (DHC == none)
    {
        return;
    }

    if ((!bPlayersVsBots || (Level.NetMode == NM_Standalone)) && bBalanceTeams && (Bot(C) != none) && (!bCustomBots || (Level.NetMode != NM_Standalone)))
    {
        BotTeam = C.PlayerReplicationInfo.Team;

        if (BotTeam == Teams[0])
        {
            OtherTeam = Teams[1];
        }
        else
        {
            OtherTeam = Teams[0];
        }

        if (OtherTeam.Size < BotTeam.Size - 1)
        {
            C.Destroy();

            return;
        }
    }

    if (bMustJoinBeforeStart && (UnrealPlayer(C) != none) && UnrealPlayer(C).bLatecomer)
    {
        return;
    }

    if (C.PlayerReplicationInfo.bOutOfLives)
    {
        return;
    }

    if (C.IsA('Bot') && TooManyBots(C))
    {
        C.Destroy();

        return;
    }

    if (bRestartLevel && Level.NetMode != NM_DedicatedServer && Level.NetMode != NM_ListenServer)
    {
        return;
    }

    if (!SpawnLimitReached(C.PlayerReplicationInfo.Team.TeamIndex) && GetStateName() == 'RoundInPlay')
    {
        SpawnManager.SpawnPlayer(DHC, SpawnError);

        if (bHandleReinforcements)
        {
            HandleReinforcements(C);
        }

        // If we've reached the last reinforcement, lets alert the team
        if (SpawnLimitReached(C.PlayerReplicationInfo.Team.TeamIndex))
        {
            SendReinforcementMessage(C.PlayerReplicationInfo.Team.TeamIndex, 1);
        }
    }

    if (SpawnError != class'DHSpawnManager'.default.SpawnError_None)
    {
        Warn("Spawn Error =" @ SpawnError);
    }
}

// Functionally identical to ROTeamGame.ChangeTeam except we reset additional parameters in DHPlayer
function bool ChangeTeam(Controller Other, int Num, bool bNewTeam)
{
    local UnrealTeamInfo NewTeam;
    local DHPlayer       P;

    if (bMustJoinBeforeStart && GameReplicationInfo.bMatchHasBegun)
    {
        return false; // only allow team changes before match starts
    }

    if (CurrentGameProfile != none && !CurrentGameProfile.CanChangeTeam(Other, Num))
    {
        return false;
    }

    if (Other.IsA('PlayerController') && Other.PlayerReplicationInfo.bOnlySpectator)
    {
        Other.PlayerReplicationInfo.Team = none;

        return true;
    }

    NewTeam = Teams[PickTeam(num,Other)];

    // Check if already on this team
    if (Other.PlayerReplicationInfo.Team == NewTeam)
    {
        return false;
    }

    Other.StartSpot = none;

    if (Other.PlayerReplicationInfo.Team != none)
    {
        Other.PlayerReplicationInfo.Team.RemoveFromTeam(Other);

        P = DHPlayer(Other);

        if (P != none)
        {
            P.DesiredRole = -1;
            P.CurrentRole = -1;
            //ROPlayerReplicationInfo(Other.PlayerReplicationInfo).RoleInfo = none;
            P.PrimaryWeapon = -1;
            P.SecondaryWeapon = -1;
            P.GrenadeWeapon = -1;
            P.bWeaponsSelected = false;

            // DARKEST HOUR
            P.SpawnPointIndex = -1;
            P.SpawnVehicleIndex = -1;
            P.VehiclePoolIndex = -1;
        }
    }

    if (NewTeam.AddToTeam(Other))
    {
        if (NewTeam == Teams[ALLIES_TEAM_INDEX])
        {
            BroadcastLocalizedMessage(GameMessageClass, 3, Other.PlayerReplicationInfo, none, NewTeam);
        }
        else
        {
            BroadcastLocalizedMessage(GameMessageClass, 12, Other.PlayerReplicationInfo, none, NewTeam);
        }

        if (bNewTeam && PlayerController(Other) != none)
        {
            GameEvent("TeamChange", "" $ Num, Other.PlayerReplicationInfo);
        }
    }

    // Since we're changing teams, remove all rally points/help requests/etc
    ClearSavedRequestsAndRallyPoints(ROPlayer(Other), false);

    return true;
}

// Modified to support one normal kick, then session kick for FF violation
function HandleFFViolation(PlayerController Offender)
{
    local bool   bSuccess;
    local string OffenderID;
    local int    i;

    if (FFPunishment == FFP_None || Level.NetMode == NM_Standalone)
    {
        return;
    }

    OffenderID = Offender.GetPlayerIDHash();

    BroadcastLocalizedMessage(GameMessageClass, 14, Offender.PlayerReplicationInfo);
    log("Kicking" @ Offender.GetHumanReadableName() @ "due to a friendly fire violation.");

    // The player has been kicked once and needs to be session kicked
    if (FFPunishment == FFP_Kick && bSessionKickOnSecondFFViolation)
    {
        for (i = 0; i < FFViolationIDs.Length; ++i)
        {
            //Level.Game.Broadcast(self, "FFViolationID" $ i $ ":" @ FFViolationIDs[i], 'Say');
            if (FFViolationIDs[i] == OffenderID)
            {
                AccessControl.BanPlayer(Offender, true); //Session kick
                //Level.Game.Broadcast(self, "This offender would be session kicked:" @ OffenderID, 'Say');
                return; // need to stop here because the player has been session kicked
            }
        }
        // The player hasn't yet been punished, but is being kicked now so lets add him to FFViolationIDs
        FFViolationIDs.Insert(0, 1);
        FFViolationIDs[0] = OffenderID;
    }

    if (FFPunishment == FFP_Kick)
    {
        //Level.Game.Broadcast(self, "This offender would be kicked:" @ OffenderID, 'Say');
        bSuccess = KickPlayer(Offender);
    }
    else if (FFPunishment == FFP_SessionBan)
    {
        bSuccess = AccessControl.BanPlayer(Offender, true);
    }
    else
    {
        bSuccess = AccessControl.BanPlayer(Offender);
    }

    if (!bSuccess)
    {
        log("Unable to remove" @ Offender.GetHumanReadableName() @ "from the server.");
    }
}

// Modified to add all literal references to pre-cache material from vehicle classes, so they aren't repeated again & again for every vehicle (most were already in the Super in ROTeamGame)
static function PrecacheGameTextures(LevelInfo myLevel)
{
    super.PrecacheGameTextures(myLevel);

    // From ROWheeledVehicle:
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.explosions.fire_16frame');
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.Vehicles.DustCloud');
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.Vehicles.Dust_KickUp');
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.Vehicles.vehiclesparkhead');

    // From ROTreadCraft:
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.explosions.aptankmark_dirt');
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.explosions.aptankmark_snow');
    myLevel.AddPrecacheMaterial(Material'Effects_Tex.BulletHits.glowfinal');

    // From DH_ROTreadCraft:
    myLevel.AddPrecacheMaterial(Material'DH_VehiclesGE_tex2.ext_vehicles.Alpha');
}

defaultproperties
{
    // Default settings based on common used server settings in DH
    bIgnore32PlayerLimit=true // allows more than 32 players
    bVACSecured=true

    bSessionKickOnSecondFFViolation=true
    FFDamageLimit=0       // this stops the FF damage system from kicking based on FF damage
    FFKillLimit=4         // new default of 4 unforgiven FF kills before punishment
    FFArtyScale=0.5       // makes it so arty FF kills count as .5
    FFExplosivesScale=0.5 // make it so other explosive FF kills count as .5

    WinLimit=1 // 1 round per map, server admins are able to customize win/rounds to the level in webadmin
    RoundLimit=1

    MaxTeamDifference=2
    bAutoBalanceTeamsOnDeath=true // if teams become imbalanced it'll force the next player to die to the weaker team
    MaxIdleTime=300

    bShowServerIPOnScoreboard=true
    bShowTimeOnScoreboard=true

    // Strings/hints
    ROHints(1)="You can 'cook' an Allied Mk II grenade by pressing the opposite fire button while holding the grenade back."
    ROHints(13)="You cannot change the 30 Cal barrel, be careful not to overheat!"
    ROHints(17)="Once you've fired the Bazooka or Panzerschreck get to fresh cover FAST, as the smoke of your backblast will reveal your location. Return fire almost certainly follow!"
    ROHints(18)="Do not stand directly behind rocket weapons when they're firing; you can sustain serious injury from the exhaust!"
    ROHints(19)="AT soldiers should always take a friend with them for ammo supplies, faster reloads and protection."
    ROHints(20)="AT weapons will be automatically unloaded if you change to another weapon. It is a good idea to stick with a team-mate to speed up reloading when needed."
    RussianNames(0)="Colin Basnett"
    RussianNames(1)="Graham Merrit"
    RussianNames(2)="Ian Campbell"
    RussianNames(3)="Eric Parris"
    RussianNames(4)="Tom McDaniel"
    RussianNames(5)="Sam Cousins"
    RussianNames(6)="Jeff Duquette"
    RussianNames(7)="Chris Young"
    RussianNames(8)="Kenneth Kjeldsen"
    RussianNames(9)="John Wayne"
    RussianNames(10)="Clint Eastwood"
    RussianNames(11)="Tom Hanks"
    RussianNames(12)="Leroy Jenkins"
    RussianNames(13)="Telly Savalas"
    RussianNames(14)="Audie Murphy"
    RussianNames(15)="George Baker"
    GermanNames(0)="Günther Liebing"
    GermanNames(1)="Heinz Werner"
    GermanNames(2)="Rudolf Giesler"
    GermanNames(3)="Seigfried Hauber"
    GermanNames(4)="Gustav Beier"
    GermanNames(5)="Joseph Peitsch"
    GermanNames(6)="Willi Eiken"
    GermanNames(7)="Wolfgang Steyer"
    GermanNames(8)="Rolf Steiner"
    GermanNames(9)="Anton Müller"
    GermanNames(10)="Klaus Triebig"
    GermanNames(11)="Hans Grüschke"
    GermanNames(12)="Wilhelm Krüger"
    GermanNames(13)="Herrmann Dietrich"
    GermanNames(14)="Erich Klein"
    GermanNames(15)="Horst Altmann"
    Acronym="DH"
    MapPrefix="DH"
    BeaconName="DH"
    GameName="DarkestHourGame"

    // Class references
    LoginMenuClass="DH_Interface.DHPlayerSetupPage"
    DefaultPlayerClassName="DH_Engine.DH_Pawn"
    ScoreBoardType="DH_Interface.DHScoreBoard"
    HUDType="DH_Engine.DHHud"
    MapListType="DH_Interface.DHMapList"
    BroadcastHandlerClass="DH_Engine.DHBroadcastHandler"
    PlayerControllerClassName="DH_Engine.DHPlayer"
    GameReplicationInfoClass=class'DH_Engine.DHGameReplicationInfo'
    VoiceReplicationInfoClass=class'DH_Engine.DHVoiceReplicationInfo'
    VotingHandlerType="DH_Engine.DHVotingHandler"
    DecoTextName="DH_Engine.DarkestHourGame"
    ObstacleManagerClass=class'DH_Engine.DHObstacleManager'
}
