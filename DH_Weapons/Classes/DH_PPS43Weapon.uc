//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2020
//==============================================================================

class DH_PPS43Weapon extends DHFastAutoWeapon;

defaultproperties
{
    ItemName="PPS-43"
    SwayModifyFactor=0.65 // -0.15 because its a light SMG
    FireModeClass(0)=class'DH_Weapons.DH_PPS43Fire'
    FireModeClass(1)=class'DH_Weapons.DH_PPS43MeleeFire'
    AttachmentClass=class'DH_Weapons.DH_PPS43Attachment'
    PickupClass=class'DH_Weapons.DH_PPS43Pickup'

    Mesh=SkeletalMesh'DH_Pps43_1st.PPS-43-1st'
    HighDetailOverlay=shader'Weapons1st_tex.SMG.PPS43_S'
    bUseHighDetailOverlayIndex=true
    HighDetailOverlayIndex=2

    IronSightDisplayFOV=50.0

    MaxNumPrimaryMags=10
    InitialNumPrimaryMags=10

    InitialBarrels=1
    BarrelClass=class'DH_Weapons.DH_GenericSMGBarrel'
    BarrelSteamBone="Muzzle"

    IdleEmptyAnim="idle_empty"
    IronIdleEmptyAnim="iron_idle_empty"
    IronBringUpEmpty="iron_in_empty"
    IronPutDownEmpty="iron_out_empty"
    SprintStartEmptyAnim="sprint_start_empty"
    SprintLoopEmptyAnim="sprint_middle_empty"
    SprintEndEmptyAnim="sprint_end_empty"

    CrawlForwardEmptyAnim="crawlF_empty"
    CrawlBackwardEmptyAnim="crawlB_empty"
    CrawlStartEmptyAnim="crawl_in_empty"
    CrawlEndEmptyAnim="crawl_out_empty"

    SelectEmptyAnim="draw_empty"
    PutDownEmptyAnim="put_away_empty"
}
