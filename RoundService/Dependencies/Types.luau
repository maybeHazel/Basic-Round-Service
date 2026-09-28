const types = {}



export type CustomRoundSettings = {

	CustomRoundTime : number;

	CustomIntermissionTime : number;

	CustomWeaponsAmount : number;

	CustomCountDownWaitTime : number;

	

	CustomMap : string;

	

	AutoEndRound : boolean;

	SortWeapons : boolean;

	

	BlacklistedMaps : {MapName: string};

	BlacklistedItems : {ItemName: string};

	HumanoidStates : {property: string, value: any};

}



return types
