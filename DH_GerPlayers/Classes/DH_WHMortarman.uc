class DH_WHMortarman extends DH_Heer;

function class<ROHeadgear> GetHeadgear()
{
	if (FRand() < 0.2)
		return Headgear[0];
	else
		return Headgear[1];
}

defaultproperties
{
     bCanUseMortars=True
     bCarriesMortarAmmo=False
     MyName="Mortar Operator"
     AltName="Werfersch�tze"
     Article="a "
     PluralName="Mortar Operators"
     InfoText="The mortar operator is tasked with providing indirect fire on distant targets using his medium mortar.  The mortar operator should work closely with a mortar observer to accurately bombard targets out of visual range.||* Targets marked by a mortar observer will appear on your situation map.|* Rounds that land near the marked target will appear on your situation map."
     menuImage=Texture'DHGermanCharactersTex.Icons.WH_MortarOperator'
     Models(0)="WH_1"
     Models(1)="WH_2"
     Models(2)="WH_3"
     Models(3)="WH_4"
     SleeveTexture=Texture'Weapons1st_tex.Arms.german_sleeves'
     PrimaryWeapons(0)=(Item=Class'DH_Weapons.DH_Kar98Weapon',Amount=18,AssociatedAttachment=Class'ROInventory.ROKar98AmmoPouch')
     GivenItems(0)="DH_Mortars.DH_Kz8cmGrW42Weapon"
     GivenItems(1)="DH_Equipment.DH_GerBinocularsItem"
     Headgear(0)=Class'DH_GerPlayers.DH_HeerHelmetThree'
     Headgear(1)=Class'DH_GerPlayers.DH_HeerHelmetTwo'
     limit=1
}
