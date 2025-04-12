proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'GHAST_TEAR', button: 'right', hand: 'main_hand'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		@entity = shoot_projectile(player(), 'SNOWBALL');
		set_projectile_item(@entity, array(name: 'GHAST_TEAR'));
		@v = entity_velocity(@entity);
		@v['x'] = (@v['x'] / @v['magnitude']) * 4;
		@v['y'] = (@v['y'] / @v['magnitude']) * 4;
		@v['z'] = (@v['z'] / @v['magnitude']) * 4;
		set_entity_velocity(@entity, @v);
		play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_WOODEN_DOOR', pitch: 2, volume: 2));
		_weapon_cooldown(player(), 2000, 'GOLD_NUGGET', closure(){
			play_sound(ploc(), array(sound: 'BLOCK_WOODEN_DOOR_OPEN', pitch: 2));
		});
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'PLAYER', cause: 'PROJECTILE'), @event, @pvp) {
		if(array_index_exists(@event, 'shooter') // missing in special cases
		&& array_index_exists(@pvp['players'], @event['shooter'])) {
			if(@event['damagertype'] === 'SNOWBALL') {
				try {
					if(!get_projectile_item(@event['damager'])['name'] === 'GHAST_TEAR') {
						die();
					}
				} catch(BadEntityException @ex) {
					console('WARNING: Snowball did not exist in damage event.');
					@item = pinv(@event['shooter'], null);
					if(!@item || @item['name'] !== 'GHAST_TEAR') {
						die();
					}
				}
				modify_event('amount', 6);
				play_sound(ploc(@event['shooter']), array(sound: 'ENTITY_ARROW_HIT_PLAYER'), @event['shooter']);
			}
		}
	}
}