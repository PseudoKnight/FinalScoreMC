switch(@action) {
case 'load':
	set_pflight(@player, true);
	bind(player_toggle_flight, array('id': @player.'doublejump'), array('flying': true, 'player': @player), @e) {
		if(pinfo(player(), 5) == 0) {
			die();
		}
		cancel();
		@vel = entity_velocity(puuid());
		set_pvelocity(@vel['x'] * 1.9, 0.9, @vel['z'] * 1.9);
		play_effect(_relative(ploc(), 'up'), 'cloud', array('speed': 0, 'particleCount': 5, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0));
		set_pflight(false);
		queue_delay(2000, player().'doublejump');
		queue_push(closure(){
			set_pflight(true);
		}, player().'doublejump');
	}

	@armor = array(
		100: @pvp['arena']['classes'][@class]['kit'][100],
		101: @pvp['arena']['classes'][@class]['kit'][101],
		102: @pvp['arena']['classes'][@class]['kit'][102],
		103: @pvp['arena']['classes'][@class]['kit'][103],
	);
	bind(player_toggle_sneak, array('id': @player.'ninja'), array('player': @player), @e, @gear = @armor) {
		if(@e['sneaking']) {
			if(entity_grounded(puuid())) {
				set_pinv(array(
					100: null,
					101: null,
					102: null,
					103: null,
				));
				set_peffect(player(), 16, 0, 25);
				set_peffect(player(), 14, 0, 20);
				play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2));
			}
		} else if(!pinv(player(), 100)){
			set_pinv(@gear);
			set_peffect(player(), 14, 0, 0);
			set_peffect(player(), 16, 0, 0);
			play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2));
		}
	}
	
	bind(entity_damage, array('id': @player.'falldamage'), array('cause': 'FALL', 'id': puuid(@player)), @e, @player) {
		cancel();
		@facing = pfacing(@player);
		@facing[0] = @facing[0] + 90;
		@facing[1] = 0 - @facing[1];
		@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		@y = 0;
		@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		set_pvelocity(@player, @x, @y, @z);
		play_named_sound(ploc(@player), array('sound': 'item.armor.equip_leather'));
		set_pinv(@player, array(0: null));
		set_timeout(100, closure(){
			@facing = pfacing(@player);
			@facing[0] = @facing[0] + 90;
			@facing[1] = 0 - @facing[1];
			@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
			@y = 0;
			@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
			set_pvelocity(@player, @x, @y, @z);
			set_timeout(100, closure(){
				set_pinv(@player, array(0: array('name': 'STONE_SWORD')));
			});
		});
	}
	
	bind(player_interact, array('id': @player.'throwstar'), array('item': 399, 'player': @player), @e) {
		@v = _get_vector(pfacing(), 1.5, 0.1);
		@loc = ploc();
		@loc['x'] += @v['x'];
		@loc['y'] += 2.5 + @v['y'];
		@loc['z'] += @v['z'];
		@star = spawn_entity('DROPPED_ITEM', 1, @loc)[0];
		set_entity_spec(@star, array('itemstack': array('type': 399, 'meta': array('display': player(), 'lore': array(3))), 'pickupdelay': 1));
		set_entity_velocity(@star, @v);
		play_sound(@loc, array('sound': 'IRONGOLEM_THROW', 'pitch': 2));
		set_interval(50, closure(){
			try {
				@loc['x'] += @v['x'];
				@loc['y'] += @v['y'];
				@loc['z'] += @v['z'];
				if(get_block_at(@loc) != '0:0') {
					play_sound(@loc, array('sound': 'ANVIL_LAND', 'pitch': 2, 'volume': 0.5));
					play_effect(@loc, 'CRIT', array('particleCount', 5));
					set_entity_spec(@star, array('itemstack': array('type': 399, 'meta': array('display': player(), 'lore': array(0)))));
					clear_task();
				} else {
					set_entity_loc(@star, @loc);
				}
			} catch(BadEntityException @ex) {
				clear_task();
			}
		});
		ptake_item(399, 1);
	}
	
	bind(item_pickup, array('id': @player.'starpickup'), array('item': 399), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || !@e['item']['meta']) {
			die();
		}
		@player = @e['item']['meta']['display'];
		if(ponline(@player) && @player != player()) {
			modify_event('item', null);
			damage_entity(puuid(), integer(@e['item']['meta']['lore'][0]), puuid(@player));
			set_peffect(player(), 19, 0, 5);
		} else {
			cancel();
		}
	}

case 'unload':
	unbind(@player.'ninja');
	unbind(@player.'doublejump');
	unbind(@player.'falldamage');
	unbind(@player.'throwstar');
	unbind(@player.'starpickup');
	queue_clear(@player.'doublejump');

}
