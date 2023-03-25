// Display main/hidden genes for pandas on right click.
bind('player_interact_entity', null, array(hand: 'main_hand', clicked: 'PANDA'), @event) {
	@spec = entity_spec(@event['id']);
	@mainGene = _to_upper_camel_case(@spec['maingene']);
	@hiddenGene = _to_upper_camel_case(@spec['hiddengene']);
	action_msg("@mainGene / @hiddenGene");
}