// Protect tameable animals from damage by non-owners
bind(entity_damage, null, array('type': '/(DONKEY|HORSE|LLAMA|MULE|OCELOT|SKELETON_HORSE|WOLF|ZOMBIE_HORSE|PARROT)/'), @event) {
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
			if(length(@event['shooter']) < 17 || !get_entity_rider(@event['id'])) {
				cancel();
			}

		default:
			if(!get_entity_rider(@event['id'])) {
				modify_event('amount', 0);
			}
	}
}

# animal sitter
bind(player_interact_entity, null, array('clicked': '/(WOLF|OCELOT|PARROT)/'), @e) {
	@owner = get_mob_owner(@e['id']);
	if(@owner) {
		if(@owner != player()) {
			action_msg('Owned by '.@owner);
		} else if(!sk_can_build(entity_loc(@e['id']))) {
			set_entity_spec(@e['id'], associative_array('sitting': false));
		}
	}
}
