proc _race_spawn_items(@race) {
	set_interval(250, closure(){
		if(@race['state'] === 'ending') {
			foreach(@item in @race['items']) {
				if(@item) {
					try(entity_remove(get_entity_rider(@item)))
					try(entity_remove(@item))
				}
			}
			clear_task();
		} else {
			for(@i = 0, @i < array_size(@race['items']), @i++) {
				@itemDisplay = @race['items'][@i];
				if(!@itemDisplay) {
					@loc = @race['itemspawn'][@i];
					@loc[5] = 0;
					@item = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@item){
						set_entity_saves_on_unload(@item, false);
						set_display_entity(@item, array(
							teleportduration: 5,
							brightness: 15,
							transformation: array(
								translation: array(x: 0, y: 0.6, z: 0),
								scale: array(x: 0.8, y: 0.8, z: 0.8))));
					})[0];
					@container = spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@container){
						set_entity_saves_on_unload(@container, false);
						set_entity_spec(@container, array(item: array(name: 'GLASS')));
						set_display_entity(@container, array(
							teleportduration: 5,
							brightness: 15,
							transformation: array(
								translation: array(x: 0, y: 0.6, z: 0),
								scale: array(x: 1.2, y: 1.2, z: 1.2),
								leftRotation: array(x: 0.354, y: -0.146, z: 0.354, w: 0.854))));
					})[0];
					set_entity_rider(@item, @container);
					@race['items'][@i] = @item;
				} else if(!entity_exists(@itemDisplay)) {
					@race['items'][@i] = null;
				} else {
					@display = get_display_entity(@itemDisplay);
					if(@display['brightness']['sky'] >= 15) {
						@type = array_get_rand(@race['item']);
						set_entity_spec(@itemDisplay, array(item: @type));
						@loc = entity_loc(@itemDisplay);
						set_entity_rotation(@itemDisplay, @loc['yaw'] + 25);
						set_entity_rotation(get_entity_rider(@itemDisplay), -@loc['yaw']);
					} else {
						// 3 second countdown to respawn
						if(@display['brightness']['sky'] >= 14) {
							set_entity_spec(get_entity_rider(@itemDisplay), array(item: array(name: 'GLASS')));
						}
						set_display_entity(@itemDisplay, array(brightness: @display['brightness']['sky'] + 1));
					}
				}
			}
		}
	});
}

proc _race_activate_item(@race, @player, @kart) {
	@item = pinv(@player, 0);
	if(!@item) {
		return();
	}
	@p = @race['players'][@player];
	if(@p['itemCooldown'] > 0) {
		return();
	}
	@target = puuid(@player);
	if(@kart) {
		@target = @kart['collider'];
	}

	switch(@item['name']) {
		case 'BIG_DRIPLEAF':
			@v = entity_velocity(@target);
			@v['y'] = 1.5;
			set_entity_velocity(@target, @v);
			play_sound(@target, array(sound: 'BLOCK_PISTON_EXTEND', volume: @kart['camdist']));

		case 'CAMPFIRE':
			if(@kart) {
				@kart['speed'] *= 1.5;
				@kart['boost'] = true;
				set_pexp(@player, 98);
				@kart['loc']['y'] -= 2;
				set_entity_spec(@kart['engine'], array(blockdata: @kart['engineBlock'].'[lit=true]'));
			} else {
				set_mob_effect(@target, 'speed', 1, 10, true);
			}
			play_sound(@target, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
			play_sound(@target, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));

		case 'CAKE':
			if(@kart) {
				@kart['boost'] = true;
				set_pexp(@player, 98);
				set_entity_spec(@kart['engine'], array(blockdata: @kart['engineBlock'].'[lit=true]'));
			} else {
				set_mob_effect(@target, 'speed', 0, 10, true);
			}
			play_sound(@target, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
			play_sound(@target, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));

	}
	@p['itemCooldown'] = 20;

	// remove item and shift others over
	@items = pinv(@player);
	@newItems = associative_array();
	@nextItem = null;
	for(@i = 7, @i >= 0, @i--) {
		@newItems[@i] = @nextItem;
		@nextItem = @items[@i];
	}
	set_pinv(@player, @newItems);
	if(@kart) {
		_kart_show_item(@player, @kart);
	}
}