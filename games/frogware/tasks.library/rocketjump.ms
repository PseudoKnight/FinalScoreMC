proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Get on up there!',
		'Dynamite is a blast',
	));
	@qty = rand(1, 4);
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'RED_CANDLE', qty: @qty));
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] + 5, @region[0][2] - 1, 'custom'),
		array(@region[1][0] + 1, @region[1][1] + 5, @region[1][2] + 1, 'custom'),
		'EMERALD_BLOCK', 4);

	bind('player_interact', array(id: 'fwtask'), array(itemname: 'RED_CANDLE', button: 'right'), @event) {
		if(!_fw_player(player())|| pcooldown('RED_CANDLE')) {
			die();
		}
		cancel();
		@item = pinv(player(), null);
		@item['qty']--;
		set_pinv(player(), null, @item);
		@snowball = shoot_projectile(player(), 'SNOWBALL');
		set_projectile_item(@snowball, array(name: 'RED_CANDLE'));
		play_sound(ploc(), array(sound: 'ENTITY_ARROW_SHOOT', pitch: 0.5));
		set_pcooldown('RED_CANDLE', 50);
		set_interval(50, closure(){
			try {
				spawn_particle(location_shift(entity_loc(@snowball), 'up', 0.5), 'FLAME');
			} catch (Exception @ex) {
				clear_task();
			}
		});
	}

	bind('projectile_hit', array(id: 'fwtask2'), , array(type: 'SNOWBALL'), @event) {
		if(get_projectile_item(@event['id'])['name'] != 'RED_CANDLE') {
			die();
		}
		@loc = @event['location'];
		spawn_particle(@loc, 'EXPLOSION_LARGE');
		play_sound(@loc, associative_array(sound: 'ENTITY_GENERIC_EXPLODE', volume: 3));
		foreach(@e in entities_in_radius(@loc, 7)) {
			if(@e == @event['id'] || entity_type(@e) == 'PLAYER' && pmode(@e) == 'SPECTATOR') {
				continue();
			}
			# a delayed velocity works more consistently with grounded entities
			set_timeout(1, closure(){
				if(!entity_exists(@e)) {
					die();
				}
				@target = location_shift(entity_loc(@e), 'up');
				@dist = distance(@loc, @target);
				set_entity_velocity(@e, array(
					min(2.2, (@target['x'] - @loc['x']) / (@dist ** 2)),
					min(2.2, (@target['y'] - @loc['y']) / (@dist ** 2)),
					min(2.2, (@target['z'] - @loc['z']) / (@dist ** 2))
				));
			});
		}
	}
}

proc _fw_end_task(@secs) {
	unbind('fwtask2');
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)
		&& get_block(ploc(@p)) === 'EMERALD_BLOCK'
		&& _fw_change_team(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
		}
	}
}


