bind(player_interact_at_entity, null, array('clicked': 'ARMOR_STAND'), @event) {
	if(get_mob_name(@event['id']) == color('green').'Start') {
		@equipment = get_mob_equipment(@event['id']);
		if(@equipment['weapon'] && @equipment['weapon']['name'] == 'WOOD_SWORD' && @equipment['weapon']['meta']) {
			call_alias(@equipment['weapon']['meta']['display']);
		}
	}
}
