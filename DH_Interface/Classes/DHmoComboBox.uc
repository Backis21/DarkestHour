//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2020
//==============================================================================

class DHmoComboBox extends moComboBox;

function Clear()
{
    RemoveItem(0, ItemCount());
}

defaultproperties
{
    ComponentClassName="DH_Interface.DHGUIComboBox"
    LabelStyleName="DHLargeText"
    StyleName="DHSmallText"
}
