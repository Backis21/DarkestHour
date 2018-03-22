//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2018
//==============================================================================

class DHShovelMeleeFire extends DHMeleeFire;

var Sound TearDownSound;

function Sound GetGroundBashSound(Actor HitActor, Material HitMaterial)
{
    local DHConstruction C;

    C = DHConstruction(HitActor);

    if (C != none)
    {
        if (C.CanTakeTearDownDamageFromPawn(Instigator))
        {
            return TearDownSound;
        }
        else
        {
            return super.GetGroundBashSound(HitActor, HitMaterial);
        }
    }
    else
    {
        return super.GetGroundBashSound(HitActor, HitMaterial);
    }
}

defaultproperties
{
    DamageType=class'DH_Equipment.DHShovelBashDamageType'
    TraceRange=75.0
    BashBackAnim="bash_pullback"
    BashHoldAnim="bash_hold"
    BashAnim="bash_attack"
    BashFinishAnim="bash_return"
    TearDownSound=SoundGroup'DH_WeaponSounds.Shovel.shovel_hit'
}
