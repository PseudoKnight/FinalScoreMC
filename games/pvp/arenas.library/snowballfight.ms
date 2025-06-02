proc _arena_bind_events(@id) {
	@pvp = import('pvp'.@id);
	@pvp['binds'][] = bind('entity_damage_player', null, array(damager: 'SNOWBALL'), @event, @pvp, @id) {
		@player = @event['player'];
		@damager = @event['data'];
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
		play_sound(@loc, array(sound: 'ENTITY_LLAMA_SPIT', pitch: 0.5 + rand() * 0.3, volume: 2));
		play_sound(@loc, array(sound: 'BLOCK_SNOW_BREAK', pitch: 0.8));
		@team = 0;
		if(array_index_exists(@pvp, 'team')) {
			@team = @pvp['players'][@player]['team'];
		}
		@loc = array_get_rand(@pvp['arena']['spawn'][@team]);
		set_ploc(@player, @loc);
		play_sound(@loc, array(sound: 'ENTITY_LLAMA_SPIT', pitch: 0.5 + rand() * 0.3), @player);
		play_sound(@loc, array(sound: 'BLOCK_SNOW_BREAK', pitch: 0.8), @player);
		_player_equip(@id, @player);
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'SNOWMAN', cause: 'PROJECTILE', world: @pvp['arena']['world']), @event, @id) {
		@loc = entity_loc(@event['id']);
		@loc['y'] += 1;
		play_sound(@loc, array(sound: 'ENTITY_ZOMBIE_INFECT'));
		spawn_particle(@loc, array(
			particle: 'CLOUD',
			speed: 0,
			count: 20,
			xoffset: 0.4,
			zoffset: 0.4,
			yoffset: 0.8
		));
		entity_remove(@event['id']);
	}

	@pvp['binds'][] = bind('item_pickup', array(priority: 'HIGHEST'), array(itemname: 'SNOWBALL'), @event, @pvp, @id) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		consume();
		@pickedup = true;
		if(!pinv(player(), 0)) {
			set_pinv(player(), 0, array(name: 'SNOWBALL'));
		} else if(!pinv(player(), -106)) {
			set_pinv(player(), -106, array(name: 'SNOWBALL'));
		} else {
			@item = pinv(player(), 2);
			if(!@item) {
				set_pinv(player(), 2, array(name: 'SNOW'));
			} else if(@item['name'] == 'SNOW') {
				if(@item['qty'] == 7) {
					set_pinv(player(), 2, array(name: 'SNOW_GOLEM_SPAWN_EGG', meta: array(display: 'BadSnowman')));
					play_sound(ploc(), array(sound: 'ENTITY_ITEM_PICKUP', pitch: 0.5), player());
				} else {
					@item['qty']++;
					set_pinv(player(), 2, @item);
				}
			} else {
				@pickedup = false;
				cancel();
			}
		}
		if(@pickedup) {
			modify_event('item', null);
			play_sound(ploc(), array(sound: 'ENTITY_ITEM_PICKUP', pitch: 2, volume: 0.5), player());
			@pvp['stats'][player()]['pickups']++;
		}
	}

	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'WOODEN_SHOVEL', block: 'SNOW', button: 'left'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		cancel();
		@loc = @event['location'];
		@loc['x'] += 0.5;
		@loc['y'] += 0.9;
		@loc['z'] += 0.5;
		@item = @event['item'];
		if(!@item['meta']) {
			@item['meta'] = array(damage: 0);
		}
		if(@item['meta']['damage'] >= 58) {
			set_pinv(player(), null, null);
			play_sound(@loc, array(sound: 'ITEM_SHIELD_BREAK'));
		} else {
			@item['meta']['damage']++;
			set_pinv(player(), null, @item);
		}
		@snowball = spawn_entity('DROPPED_ITEM', 1, @loc)[0];
		set_entity_spec(@snowball, array(itemstack: array(name: 'SNOWBALL')));
		play_sound(@loc, array(sound: 'BLOCK_SNOW_BREAK', pitch: 0.8));
		spawn_particle(@loc, array(particle: 'BLOCK_CRACK', block: 'SNOW_BLOCK'));
	}
}
