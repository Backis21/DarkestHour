//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2019
//==============================================================================

class DH_StuH42CannonShellSmoke extends DH_Stug3GCannonShellSmoke;

defaultproperties
{
    SmokeEmitterClass=class'DH_Effects.DHSmokeEffect_LargeShell'
    ShellDiameter=10.5
    ImpactDamage=175 // 75mm smoke shells are 125, so increased as this is a larger, heavier shell
    BallisticCoefficient=2.96 // same as 105mm HE or HEAT shells
    Speed=29874.0 // same as 105mm HE or HEAT shells
    MaxSpeed=29874.0
    Tag="10cm F.H.Gr.Nb."
    DrawScale=1.3
}
