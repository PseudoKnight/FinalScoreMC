proc _race_spawn_items(@race) {
	set_interval(250, closure(){
		if(@race['state'] === 'ending') {
			foreach(@i: @item in @race['items']) {
				if(@item) {
					try(entity_remove(get_entity_rider(@item)))
					try(entity_remove(@item))
					array_remove(@race['items'], @i);
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
					set_entity_rider(@item, spawn_entity('ITEM_DISPLAY', 1, @loc, closure(@container){
						set_entity_saves_on_unload(@container, false);
						set_entity_spec(@container, array(item: array(name: 'GLASS')));
						set_display_entity(@container, array(
							teleportduration: 5,
							brightness: 15,
							transformation: array(
								translation: array(x: 0, y: 0.6, z: 0),
								scale: array(x: 1.2, y: 1.2, z: 1.2),
								leftRotation: array(x: 0.354, y: -0.146, z: 0.354, w: 0.854))));
					})[0]);
					@race['items'][@i] = @item;
				} else if(!entity_exists(@itemDisplay)) {
					@race['items'][@i] = null;
				} else {
					// display brightness used for respawn countdown (interval duration * 15 levels)
					@displayBrightness = get_display_entity(@itemDisplay)['brightness']['sky'];
					@container = get_entity_rider(@itemDisplay);
					if(@displayBrightness < 15) {
						@displayBrightness++;
						set_display_entity(@itemDisplay, array(brightness: @displayBrightness));
						if(@displayBrightness >= 15) {
							set_entity_spec(@container, array(item: array(name: 'GLASS')));
							set_display_entity(@container, array(transformation: array(scale: array(x: 1.2, y: 1.2, z: 1.2))));
						}
					}
					if(@displayBrightness >= 15) {
						@type = array_get_rand(array_keys(@race['item']));
						set_entity_spec(@itemDisplay, array(item: array(name: @type, meta: @race['item'][@type])));
						@loc = entity_loc(@itemDisplay);
						set_entity_rotation(@itemDisplay, @loc['yaw'] + 25);
						set_entity_rotation(@container, -@loc['yaw']);
						spawn_particle(location_shift(@loc, 'up', 0.6), array(
							particle: 'END_ROD',
							count: 1,
							xoffset: 1.2,
							yoffset: 1.2,
							zoffset: 1.2,
							force: true));
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
	if(@race['players'][@player]['itemCooldown'] > 0) {
		return();
	}
	@racer = puuid(@player);
	if(@kart) {
		@racer = @kart['collider'];
	} else if(pvehicle(@racer)) {
		@racer = pvehicle(@racer);
	}

	switch(@item['name']) {
		case 'BIG_DRIPLEAF':
			@v = entity_velocity(@racer);
			@v['y'] = 1.5;
			set_entity_velocity(@racer, @v);
			play_sound(@racer, array(sound: 'BLOCK_PISTON_EXTEND', volume: @kart['camdist']));

		case 'CAMPFIRE':
			if(@kart) {
				@kart['speed'] *= 1.5;
				@kart['boost'] = array(strength: 2, ticks: 20);
				@kart['loc']['y'] -= 1; // trick kart into thinking it just went uphill
				set_entity_spec(@kart['engine'], array(blockdata: @kart['engineBlock'].'[lit=true]'));
				play_sound(@racer, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
				play_sound(@racer, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));
			} else {
				set_mob_effect(@racer, 'speed', 1, 10, true);
			}

		case 'CAKE':
			if(@kart) {
				@kart['boost'] = array(strength: 1, ticks: 40);
				set_entity_spec(@kart['engine'], array(blockdata: @kart['engineBlock'].'[lit=true]'));
				play_sound(@racer, array(sound: 'BLOCK_RESPAWN_ANCHOR_DEPLETE', volume: @kart['camdist']));
				play_sound(@racer, array(sound: 'ENTITY_GHAST_SHOOT', pitch: 0.5, volume: @kart['camdist']));
			} else {
				set_mob_effect(@racer, 'speed', 0, 10, true);
			}

		case 'LIGHTNING_ROD':
			@currentCheckpoint = @race['players'][@player]['checkpoint'];
			foreach(@p: @opponent in @race['players']) {
				if(@p !== @player && @opponent['checkpoint'] >= @currentCheckpoint) {
					if(@kart) {
						lightning(@opponent['kart']['loc'], true);
						@opponent['kart']['speed'] = 0.0;
					} else {
						lightning(ploc(@p), true);
						@baseEntity = pvehicle(@p) ||| puuid(@p);
						set_mob_effect(@baseEntity, 'slowness', 0, 10);
					}
				}
			}
			if(@kart) {
				lightning(@kart['loc'], true);
			} else {
				lightning(ploc(@player), true);
			}

		case 'WOODEN_HOE':
			@currentCheckpoint = @race['players'][@player]['checkpoint'];
			foreach(@p: @opponent in @race['players']) {
				if(@p !== @player && @opponent['checkpoint'] >= @currentCheckpoint) {
					set_peffect(@p, 'darkness', 0, 10);
					play_sound(ploc(@p), array(sound: 'ENTITY_SKELETON_HORSE_DEATH', pitch: 0.5, volume: 3), @p);
				}
			}
			play_sound(ploc(@player), array(sound: 'ENTITY_SKELETON_HORSE_DEATH', pitch: 0.5, volume: 3), @player);

		case 'LIGHT_BLUE_STAINED_GLASS':
			if(@kart) {
				set_entity_spec(@kart['shield'], array(item: array(name: 'LIGHT_BLUE_STAINED_GLASS', meta: array(enchants: array(unbreaking: 1)))));
				@kart['invulnerableTicks'] = 250;
				set_entity_invulnerable(@kart['collider'], true);
				play_sound(@kart['camera'], array(sound: 'BLOCK_BEACON_ACTIVATE', pitch: 0, volume: 3));
				set_timeout(2500, closure(){
					try(play_sound(@kart['camera'], array(sound: 'BLOCK_BEACON_AMBIENT', pitch: 0, volume: 3)))
				});
			} else {
				set_mob_effect(@racer, 'resistance', 4, 15);
				play_sound(@racer, array(sound: 'BLOCK_BEACON_ACTIVATE', pitch: 0, volume: 3));
				set_timeout(2500, closure(){
					try(play_sound(@racer, array(sound: 'BLOCK_BEACON_AMBIENT', pitch: 0, volume: 3)))
				});
			}

		case 'MAGENTA_GLAZED_TERRACOTTA':
			@currentCheckpoint = @race['players'][@player]['checkpoint'];
			foreach(@p: @opponent in @race['players']) {
				if(@p !== @player && @opponent['checkpoint'] >= @currentCheckpoint) {
					if(@kart) {
						@opponent['kart']['lockControlTicks'] = 40;
						set_entity_pose(@opponent['kart']['mannequin'], 'SNEAKING');
						play_sound(@racer, array(sound: 'ENTITY_PARROT_AMBIENT', pitch: 0, volume: 1, seed: 3));
					} else {
						@baseEntity = pvehicle(@p) ||| puuid(@p);
						set_entity_velocity(@baseEntity, array(rand() * 2 - 1, rand(), rand() * 2 - 1));
					}
				}
			}
			play_sound(ploc(@player), array(sound: 'ENTITY_PARROT_AMBIENT', pitch: 0, volume: 1, seed: 3));

	}
	@race['players'][@player]['itemCooldown'] = 40;

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