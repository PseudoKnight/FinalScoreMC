proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'SNOWBALL', button: 'right', hand: 'main_hand'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		cancel();
		@entities = array();
		for(@i = 0, @i < 8, @i++) {
			@entities[@i] = shoot_projectile(player(), 'SNOWBALL');
			set_projectile_item(@entities[@i], array(name: 'POLISHED_BLACKSTONE_BUTTON'));
			@v = entity_velocity(@entities[@i]);
			@v['x'] = ((@v['x'] / @v['magnitude']) * 3.2) + ((rand() * 1.6) - 0.8);
			@v['y'] = ((@v['y'] / @v['magnitude']) * 3.2) + ((rand() * 1.6) - 0.8);
			@v['z'] = ((@v['z'] / @v['magnitude']) * 3.2) + ((rand() * 1.6) - 0.8);
			set_entity_velocity(@entities[@i], @v);
		}
		set_timeout(250, closure(){
			foreach(@snowball in @entities) {
				try {
					entity_remove(@snowball);
				} catch(BadEntityException @ex) {
					// this ball hit something
				}
			}
		});
		play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_WOODEN_DOOR', pitch: 1.5, volume: 2));
		play_sound(ploc(), array(sound: 'ENTITY_GENERIC_EXPLODE', pitch: 2, volume: 2));
		_weapon_cooldown(player(), 1100, 'SLIME_BALL', closure(){
			play_sound(ploc(), array(sound: 'BLOCK_PISTON_CONTRACT', pitch: 1.5));
		});
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'PLAYER', cause: 'PROJECTILE'), @event, @pvp) {
		if(array_index_exists(@event, 'shooter') // missing in special cases
		&& array_index_exists(@pvp['players'], @event['shooter'])) {
			if(@event['damagertype'] === 'SNOWBALL') {
				try {
					if(!get_projectile_item(@event['damager'])['name'] !== 'POLISHED_BLACKSTONE_BUTTON') {
						die();
					}
				} catch(BadEntityException @ex) {
					console('WARNING: Snowball did not exist in damage event.');
					@item = pinv(@event['shooter'], null);
					if(!@item || @item['name'] !== 'SNOWBALL') {
						die();
					}
				}
				modify_event('amount', 6);
				play_sound(ploc(@event['shooter']), array(sound: 'ENTITY_ARROW_HIT_PLAYER'), @event['shooter']);
			}
		}
	}
}