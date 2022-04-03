proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact',null, array(itemname: 'WITHER_SKELETON_SKULL', button: 'right'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		if(@e['item'] !== 'WITHER_SKELETON_SKULL') {
			die();
		}

		@entity = shoot_projectile(player(), 'wither_skull');
		@dir = entity_spec(@entity)['direction'];
		set_entity_spec(@entity, array(direction: array(@dir['x'], @dir['y'], @dir['z'])));

		ptake_item(array(name: 'WITHER_SKELETON_SKULL'));
		cancel();
	}
}
