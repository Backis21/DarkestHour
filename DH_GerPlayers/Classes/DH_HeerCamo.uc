//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_HeerCamo extends DH_German_Units
    abstract;

defaultproperties
{
    RolePawns(0)=(PawnClass=class'DH_GerPlayers.DH_GermanCamoHeerPawn',Weight=8.0)
    RolePawns(1)=(PawnClass=class'DH_GerPlayers.DH_GermanSniperHeerPawn',Weight=1.0)
    SleeveTexture=Texture'Weapons1st_tex.Arms.german_sleeves'
}
