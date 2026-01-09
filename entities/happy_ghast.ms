/*
	Improve convenience of using Happy Ghasts
	- Speeds up (1.5x) Happy Ghasts temporarily when tempted with snowball/harness
	- Increases tempt range from 16 to 32 meters (matches wandering range from home location)
 */
bind('target_player', null, array(mobtype: 'HAPPY_GHAST', reason: 'TEMPT'), @event) {
	try {
		add_entity_attribute_modifier(@event['id'], array(
			attribute: 'GENERIC_FLYING_SPEED',
			id: 'tempt_boost',
			operation: 'MULTIPLY_SCALAR_1',
			amount: 1.5));
		set_timeout(3000, closure(){
			try(remove_entity_attribute_modifier(@event['id'], 'GENERIC_FLYING_SPEED', 'tempt_boost'))
		});
	} catch(BadEntityTypeException @ignore) {}
}

bind('player_interact_entity', null, array(clicked: 'HAPPY_GHAST'), @event) {
	remove_entity_attribute_modifier(@event['id'], 'GENERIC_FLYING_SPEED', 'tempt_boost');
	set_entity_attribute_base(@event['id'], 'TEMPT_RANGE', 32.0);
}