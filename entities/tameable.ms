// Protect tameable animals from damage by non-owners
bind(entity_damage, null, array('type': '/(DONKEY|HORSE|LLAMA|MULE|OCELOT|SKELETON_HORSE|WOLF|ZOMBIE_HORSE)/'), @event) {
	if(!_is_survival_world(@event['world'])) {
		die();
	}

	@owner = get_mob_owner(@event['id']);
	if(is_null(@owner)) {
		 die();
	}

	switch(@event['cause']) {
		case 'ENTITY_ATTACK':
			@isplayer = length(@event['damager']) < 17;

			if((@isplayer && @owner != @event['damager'])
			|| (!@isplayer && !get_entity_rider(@event['id']))) {
				cancel();
			}

		case 'PROJECTILE':
			@isplayer = length(@event['shooter']) < 17;

			if((@isplayer && @owner != @event['shooter'])
			|| (!@isplayer && !get_entity_rider(@event['id']))) {
				cancel();
			}

		default:
			if(!get_entity_rider(@event['id'])) {
				modify_event('amount', 0);
			}
	}
}

# animal sitter
bind(player_interact_entity, null, array('clicked': '/(WOLF|OCELOT)/'), @e) {
	if(!sk_can_build(entity_loc(@e['id'])) && get_mob_owner(@e['id']) == player()) {
		set_entity_spec(@e['id'], associative_array('sitting': false));
	}
}
