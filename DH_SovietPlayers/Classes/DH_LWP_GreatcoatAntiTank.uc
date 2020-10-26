//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2020
//==============================================================================

class DH_LWP_GreatcoatAntiTank extends DHPOLAntiTankRoles;

defaultproperties
{
    RolePawns(0)=(PawnClass=class'DH_SovietPlayers.DH_LWPGreatcoatBrownBagPawn',Weight=1.0)
    Headgear(0)=class'DH_SovietPlayers.DH_LWPHelmet'
    SleeveTexture=Texture'DHSovietCharactersTex.RussianSleeves.DH_RussianCoatSleeves'
    Grenades(0)=(Item=class'DH_Weapons.DH_RPG43GrenadeWeapon')
    GivenItems(0)="none"
}