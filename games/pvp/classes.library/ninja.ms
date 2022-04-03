proc _class_load(@player, @pvp) {
	set_pflight(@player, true);
	bind('player_toggle_flight', array(id: @player.'doublejump'), array(flying: true, player: @player), @e) {
		if(pmode() == 'SPECTATOR') {
			die();
		}
		cancel();
		@vel = entity_velocity(puuid());
		set_pvelocity(@vel['x'] * 1.9, 0.9, @vel['z'] * 1.9);
		spawn_particle(location_shift(ploc(), 'up'), array(particle: 'CLOUD', speed: 0, count: 5, xoffset: 0.4, zoffset: 0.4, yoffset: 0));
		set_pflight(false);
		set_entity_fall_distance(puuid(), 0);
		queue_delay(2000, player().'doublejump');
		queue_push(closure(){
			set_pflight(true);
		}, player().'doublejump');
	}

	@classname = @pvp['players'][@player]['class'];
	@armor = array(
		100: @pvp['arena']['classes'][@classname]['kit'][100],
		101: @pvp['arena']['classes'][@classname]['kit'][101],
		102: @pvp['arena']['classes'][@classname]['kit'][102],
		103: @pvp['arena']['classes'][@classname]['kit'][103],
	);
	bind('player_toggle_sneak', array(id: @player.'ninja'), array(player: @player), @e, @gear = @armor) {
		if(@e['sneaking']) {
			if(entity_grounded(puuid())) {
				set_pinv(array(
					100: null,
					101: null,
					102: null,
					103: null,
				));
				set_peffect(player(), 'NIGHT_VISION', 0, 25);
				set_peffect(player(), 'INVISIBILITY', 0, 20);
				spawn_particle(location_shift(ploc(), 'up', 2), array(
					particle: 'SPELL',
					speed: 0,
					count: 10,
					yoffset: 0.4,
					xoffset: 0.2,
					zoffset: 0.2
				));
			}
		} else if(!pinv(player(), 100)){
			set_pinv(@gear);
			set_peffect(player(), 'INVISIBILITY', 0, 0);
			set_peffect(player(), 'NIGHT_VISION', 0, 0);
			spawn_particle(location_shift(ploc(), 'up', 2) ,array(
				particle: 'SPELL',
				speed: 0,
				count: 10,
				yoffset: 0.4,
				xoffset: 0.2,
				zoffset: 0.2
			));
		}
	}
	
	bind('entity_damage', array(id: @player.'falldamage'), array(cause: 'FALL', id: puuid(@player)), @e, @player) {
		cancel();
		@facing = pfacing(@player);
		@facing[0] = @facing[0] + 90;
		@facing[1] = 0 - @facing[1];
		@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		@y = 0;
		@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		set_pvelocity(@player, @x, @y, @z);
		play_sound(ploc(@player), array(sound: 'ITEM_ARMOR_EQUIP_LEATHER'));
		set_pinv(@player, 0, null);
		set_timeout(100, closure(){
			@facing = pfacing(@player);
			@facing[0] = @facing[0] + 90;
			@facing[1] = 0 - @facing[1];
			@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
			@y = 0;
			@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
			set_pvelocity(@player, @x, @y, @z);
			set_timeout(100, closure(){
				set_pinv(@player, 0, array(name: 'STONE_SWORD'));
			});
		});
	}
	
	bind('player_interact', array(id: @player.'throwstar'), array(itemname: 'NETHER_STAR', player: @player), @e) {
		@v = get_vector(ploc(), 1.5);
		@v['y'] += 0.1;
		@x = @v['x'];
		@y = @v['y'];
		@z = @v['z'];
		@loc = ploc();
		@loc['x'] += @x;
		@loc['y'] += @y + 2.4;
		@loc['z'] += @z;
		@star = drop_item(@loc, array(name: 'NETHER_STAR', meta: array(display: player(), lore: array(3))), false);
		set_entity_spec(@star, array(pickupdelay: 1));
		set_entity_velocity(@star, @v);
		play_sound(@loc, array(sound: 'ENTITY_IRON_GOLEM_ATTACK', pitch: 2));
		set_interval(50, closure(){
			try {
				@loc['x'] += @x;
				@loc['y'] += @y;
				@loc['z'] += @z;
				if(get_block(@loc) != 'AIR') {
					play_sound(@loc, array(sound: 'BLOCK_ANVIL_LAND', pitch: 2, volume: 0.5));
					spawn_particle(@loc, array(particle: 'CRIT', 'count', 5));
					set_entity_spec(@star, array(itemstack: array(name: 'NETHER_STAR', meta: array(display: player(), lore: array(0)))));
					clear_task();
				} else {
					set_entity_loc(@star, @loc);
				}
			} catch(BadEntityException @ex) {
				clear_task();
			}
		});
		ptake_item(array(name: 'NETHER_STAR'));
	}
	
	bind('item_pickup', array(id: @player.'starpickup'), array(itemname: 'NETHER_STAR'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || !@e['item']['meta']) {
			die();
		}
		@player = @e['item']['meta']['display'];
		if(ponline(@player) && @player != player()) {
			modify_event('item', null);
			set_peffect(player(), 'POISON', 0, 5);
			damage_entity(puuid(), integer(@e['item']['meta']['lore'][0]), puuid(@player));
		} else {
			cancel();
		}
	}
}
	
proc _class_powerup(@player) {
	set_parrow_count(@player, 0);
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'ninja');
	unbind(@player.'doublejump');
	unbind(@player.'falldamage');
	unbind(@player.'throwstar');
	unbind(@player.'starpickup');
	queue_clear(@player.'doublejump');
}
