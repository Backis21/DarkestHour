//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_AmericanHelmet82ndEMb extends DH_Headgear;

static function StaticPrecache(LevelInfo L)
{
//  L.AddPrecacheMaterial(Material'DHUSCharactersTex.Gear.US_29thID_Headgear');
}

defaultproperties
{
    Mesh=SkeletalMesh'dhgear_anm.US_Airborne_Helmet2'
    Skins(0)=Texture'DHUSCharactersTex.Gear.US_EM_headgear2'
}
