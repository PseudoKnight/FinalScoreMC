// Protect tameable animals from damage by non-owners
bind('entity_damage', array(priority: 'HIGHEST'), array('type': '/(DONKEY|HORSE|LLAMA|MULE|CAT|SKELETON_HORSE|WOLF|ZOMBIE_HORSE|PARROT)/'), @event) {
	@world = @event['world'];
	@id = @event['id'];
	if(!_is_survival_world(@world)) {
		die();
	}

	@owner = get_mob_owner(@id);
	if(is_null(@owner)) {
		 die();
	}

	switch(@event['cause']) {
		case 'ENTITY_ATTACK':
			@isplayer = @event['damagertype'] === 'PLAYER';
			@damager = @event['damager'];

			if((@isplayer && @owner != @damager)
			|| (!@isplayer && !get_entity_rider(@id))) {
				cancel();
				consume();
				if(@isplayer) {
					@spec = entity_spec(@id);
					@regions = sk_regions_at(@event['location']);
					if(@regions && array_index_exists(@spec, 'sitting') && @spec['sitting']
					&& array_contains(sk_region_owners(@regions[-1], @world)['players'], puuid(@damager))) {
						if(ponline(@owner) && _is_survival_world(pworld(@owner))) {
							set_entity_loc(@id, location_shift(ploc(@owner), 'up'));
							tmsg(@damager, color('yellow').'Teleported '.@event['type'].' to '.@owner.'.');
						} else {
							@ownerdata = _pdata(@owner);
							if(array_index_exists(@ownerdata, 'homes') && array_index_exists(@ownerdata['homes'], @world)) {
								set_entity_loc(@id, location_shift(@ownerdata['homes'][@world], 'up'));
								tmsg(@damager, color('yellow').'Teleported '.@event['type'].' to '.@owner.'\'s home.');
							}
						}
					}
				}
			}

		case 'PROJECTILE':
			if(array_index_exists(@event, 'shooter') && length(@event['shooter']) < 17 || !get_entity_rider(@id)) {
				cancel();
				consume();
			}

		default:
			if(!get_entity_rider(@id)) {
				modify_event('amount', 0);
			}
	}
}

# animal sitter
bind('player_interact_entity', null, array('clicked': '/(WOLF|CAT|PARROT)/'), @e) {
	@owner = get_mob_owner(@e['id']);
	if(@owner) {
		if(@owner != player()) {
			action_msg('Owned by '.@owner);
		} else if(!sk_can_build(entity_loc(@e['id']))) {
			set_entity_spec(@e['id'], associative_array('sitting': false));
		}
	}
}
