@pvp['binds'][] = bind('player_interact', null, array(itemname: 'ANVIL', button: 'right'), @event, @pvp) {
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}
	@taken = ptake_item(array(name: 'SLIME_BALL', qty: 1));
	if(@taken) {
		@entity = shoot_projectile(player(), 'SNOWBALL');
		set_projectile_item(@entity, array(name: 'SLIME_BALL'));
		@v = entity_velocity(@entity);
		@v['x'] = (@v['x'] / @v['magnitude']) * 4;
		@v['y'] = (@v['y'] / @v['magnitude']) * 4;
		@v['z'] = (@v['z'] / @v['magnitude']) * 4;
		set_entity_velocity(@entity, @v);
		play_sound(ploc(), array(sound: 'BLOCK_SLIME_BLOCK_HIT', volume: 2));
		play_sound(ploc(), array(sound: 'BLOCK_BONE_BLOCK_PLACE', pitch: 0.5, volume: 2));
	}
}

@pvp['binds'][] = bind('projectile_hit', null, array(type: 'SNOWBALL'), @event, @pvp) {
	@item = get_projectile_item(@event['id']);
	if(@item && @item['name'] == 'SLIME_BALL') {
		@v = entity_velocity(@event['id']);
		@loc = @event['location'];
		@loc['yaw'] = get_yaw(array(0, 0, 0), @v);
		@loc['pitch'] = get_pitch(array(0, 0, 0), @v);
		@hit = ray_trace(@event['shooter'], @loc, 4, 0.2)['location'];
		play_sound(@hit, array(sound: 'BLOCK_SLIME_BLOCK_PLACE', pitch: 1.3));
		@slime = spawn_entity('ARMOR_STAND', 1, location_shift(@hit, 'down', 0.75), closure(@stand) {
			set_entity_spec(@stand, array(small: true, gravity: false, visible: false));
			set_mob_equipment(@stand, array(HELMET: array(name: 'SLIME_BLOCK')));
		})[0];
		set_timeout(2000, closure(){
			try {
				entity_remove(@slime);
				@bind = bind('entity_damage', null, array(type: 'PLAYER'), @event, @damager = player(@event['shooter']), @pvp) {
					if(array_index_exists(@pvp['players'], @event['player'])) {
						_stats_damage(@damager, @event['player'], @event['amount'], @pvp);
					}
				}
				explosion(@hit, 1, true);
				unbind(@bind);
			} catch (BadEntityException @ex) {
				// doesn't exist, don't explode
			}
		});
	}
}
