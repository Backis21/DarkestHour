//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2017
//==============================================================================

class DH_SVT40MeleeFire extends DHMeleeFire;

// Modified to remove TweenTime for the post stab anim as it causes a visual glitch on this weapon - hacky, but works for now
function PlayFireEnd()
{
    if (Weapon != none && Weapon.Mesh != none)
    {
        if (Weapon.bBayonetMounted && Weapon.HasAnim(BayoFinishAnim))
        {
            Weapon.PlayAnim(BayoFinishAnim, FireEndAnimRate, 0.0); // zero here instead of TweenTime
        }
        else if (Weapon.AmmoAmount(0) < 1 && Weapon.HasAnim(BashFinishEmptyAnim))
        {
            Weapon.PlayAnim(BashFinishEmptyAnim, FireEndAnimRate, TweenTime);
        }
        else if (Weapon.HasAnim(BashFinishAnim))
        {
            Weapon.PlayAnim(BashFinishAnim, FireEndAnimRate, TweenTime);
        }
    }
}

defaultproperties
{
    DamageType=class'DH_Weapons.DH_SVT40BashDamType'
    BayonetDamageType=class'DH_Weapons.DH_SVT40BayonetDamType'
    BayonetTraceRange=115.0
    BayoBackAnim="stab_pullback"
    BayoHoldAnim="stab_hold"
    BayoStabAnim="stab_attack"
    BayoFinishAnim="stab_return"
}
