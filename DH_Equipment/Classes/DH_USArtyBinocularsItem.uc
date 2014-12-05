//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_USArtyBinocularsItem extends DH_BinocularsItem;

// Attempt to save the artillery strike positions
simulated function Fire(float F)
{
    // added check for player to be in iron view to save arty coords - Antarian
    if ((Instigator == none) || (Instigator.Controller == none)
        || (AIController(Instigator.Controller) != none) || !bUsingSights)
       return;

        // server
    if (Instigator.IsLocallyControlled())
    {
       DHPlayer(Instigator.Controller).ServerSaveArtilleryPosition();
    }
}

defaultproperties
{
    AttachmentClass=class'DH_Equipment.DH_USArtyBinocularsAttachment'
}
