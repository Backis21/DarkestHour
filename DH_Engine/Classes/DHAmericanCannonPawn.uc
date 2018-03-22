//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DHAmericanCannonPawn extends DHVehicleCannonPawn
    abstract;

defaultproperties
{
    RangeText="yards" // US sights don't show range text as default, but if any cannons do then this is the range text to use
    PeriscopeOverlay=Texture'DH_VehicleOptics_tex.General.PERISCOPE_overlay_Allied'
    BinocsOverlay=Texture'DH_VehicleOptics_tex.General.BINOC_overlay_7x50Allied'
}
