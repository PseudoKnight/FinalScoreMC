proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@pvp['binds'][] = bind('entity_damage_player', null, array(damager: 'SNOWBALL'), @e, @pvp, @id) {
		@player = @e['player'];
		@damager = @e['data'];
		if(!array_index_exists(@pvp['players'], @player)) {
			die();
		}
		if(array_index_exists(@pvp['players'], @damager)) {
			if(array_index_exists(@pvp, 'team')
			&& @pvp['players'][@player]['team'] == @pvp['players'][@damager]['team']) {
				die();
			}
			@pvp['stats'][@damager]['kills']++;
		}
		@pvp['stats'][@player]['deaths']++;
		@loc = location_shift(ploc(@player), 'up', 2);
		spawn_particle(@loc, array(
			particle: 'SNOWBALL',
			count: 20,
			xoffset: 0.5,
			yoffset: 1,
			zoffset: 0.5,
		));
		play_sound(@loc, associative_array(sound: 'ENTITY_LLAMA_SPIT', pitch: 0.5, volume: 2));
		@team = 0;
		if(array_index_exists(@pvp, 'team')) {
			@team = @pvp['players'][@player]['team'];
		}
		@loc = array_get_rand(@pvp['arena']['spawn'][@team]);
		set_ploc(@player, @loc);
		play_sound(@loc, associative_array(sound: 'ENTITY_LLAMA_SPIT', pitch: 0.5), @player);
		_player_equip(@id, @player);
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'SNOWMAN', cause: 'PROJECTILE', world: @pvp['arena']['lobby'][3]), @e, @id) {
		@loc = entity_loc(@e['id']);
		@loc['y'] += 1;
		play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_INFECT'));
		spawn_particle(@loc, array(
			particle: 'CLOUD',
			speed: 0,
			count: 10,
			xoffset: 0.4,
			zoffset: 0.4,
			yoffset: 0.4
		));
		entity_remove(@e['id']);
	}

	@pvp['binds'][] = bind('item_pickup', array(priority: 'HIGHEST'), array(itemname: 'SNOWBALL'), @e, @pvp, @id) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		consume();
		if(!pinv(player(), 0)) {
			modify_event('item', null);
			set_pinv(player(), 0, array(name: 'SNOWBALL'));
			play_sound(ploc(), array(sound: 'ENTITY_ITEM_PICKUP', pitch: 2, volume: 0.5), player());
			@pvp['stats'][player()]['pickups']++;
		} else if(!pinv(player(), -106)) {
			modify_event('item', null);
			set_pinv(player(), -106, array(name: 'SNOWBALL'));
			play_sound(ploc(), array(sound: 'ENTITY_ITEM_PICKUP', pitch: 2, volume: 0.5), player());
			@pvp['stats'][player()]['pickups']++;
		} else {
			cancel();
		}
	}

	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'WOODEN_SHOVEL', block: 'SNOW', button: 'left'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		cancel();
		@loc = @e['location'];
		@loc['x'] += 0.5;
		@loc['y'] += 0.9;
		@loc['z'] += 0.5;
		@snowball = spawn_entity('DROPPED_ITEM', 1, @loc)[0];
		set_entity_spec(@snowball, array(itemstack: array(name: 'SNOWBALL')));
		play_sound(@loc, associative_array(sound: 'BLOCK_SNOW_BREAK', pitch: 0.8));
	}

	@pvp['binds'][] = bind('block_break', null, null, @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		cancel();
	}
}
