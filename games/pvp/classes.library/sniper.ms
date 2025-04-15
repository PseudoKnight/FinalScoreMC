proc _class_load(@player, @pvp) {
	set_pcooldown(@player, 'SPYGLASS', 0);
	bind('player_interact', array(id: @player.'usesnipeglass'), array(itemname: 'SPYGLASS', hand: 'main_hand', player: @player), @event, @pvp) {
		@laser = spawn_entity('TEXT_DISPLAY', 1, ploc(), closure(@e) {
			set_entity_spec(@e, array(
				text: color('red').'⬤',
				opacity: 128,
				bgcolor: array(r: 0, g: 0, b: 0, a: 0)));
			set_display_entity(@e, array(
				teleportduration: 1,
				viewrange: 128,
				brightness: 15,
				transformation: array(
					translation: array(x: -0.02, y: -0.117, z: 0.0))));
			set_entity_saves_on_unload(@e, false);
		})[0];
		@slot = pheld_slot();
		set_interval(50, closure(){
			@item = pinv(player(), null);
			if(!@item || @item['name'] !== 'SPYGLASS') {
				clear_task();
				try(entity_remove(@laser))
			} else {
				@trace = ray_trace(128);
				if(@trace['entities']) {
					// shine a light in their face with worldborder?
					@loc = @trace['entities'][0]['location'];
					@loc['yaw'] = pfacing()[0] + 180;
					@loc['pitch'] = neg(pfacing()[1]);
					set_entity_loc(@laser, @loc);
					set_entity_spec(@laser, array(opacity: 128 + rand(32)));
				} else if(@trace['hitblock']) {
					@loc = @trace['location'];
					switch(@trace['hitface']) {
						case 'UP':
							@loc['pitch'] = -90;
							@loc['y'] += 0.01;
						case 'DOWN':
							@loc['pitch'] = 90;
							@loc['y'] -= 0.01;
						case 'WEST':
							@loc['yaw'] = 90.0;
							@loc['x'] -= 0.01;
						case 'EAST':
							@loc['yaw'] = 270.0;
							@loc['x'] += 0.01;
						case 'SOUTH':
							@loc['yaw'] = 0.0;
							@loc['z'] += 0.01;
						case 'NORTH':
							@loc['yaw'] = 180.0;
							@loc['z'] -= 0.01;
					}
					set_entity_loc(@laser, @loc);
					set_entity_spec(@laser, array(opacity: 128 + rand(32)));
				} else {
					set_entity_spec(@laser, array(opacity: 25));
				}
			}
		});
	}

	bind('player_stop_using_item', array(id: @player.'stopsnipeglass'), array(itemname: 'SPYGLASS', player: @player), @event, @pvp) {
		set_pcooldown('SPYGLASS', 9999999);
		@trace = array(raySize: 0.06);
		if(@event['ticks'] < 8) {
			@trace['inaccuracy'] = (8 - @event['ticks']) * 3; // up to 21 degrees of inaccuracy
		}
		_weapon_hit_scan(player(), @trace, 10, array(
			tracer: 'CRIT', 
			display: 'gray_stained_glass',
			hitparticle: 'CAMPFIRE_COSY_SMOKE'), @pvp);
		play_sound(ploc(), array(sound: 'ENTITY_LIGHTNING_BOLT_THUNDER', seed: 4, pitch: 2, volume: 3));
		play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST_FAR', pitch: 2, volume: 3));
	}

	bind('player_interact', array(priority: 'HIGHEST', id: @player.'reloadsnipeglass'), array(itemname: 'IRON_NUGGET', hand: 'main_hand', player: @player), @event, @pvp) {
		consume();
		if(pcooldown('SPYGLASS') < 3000 / 50) {
			die();
		}
		@ammo = pinv(player(), null);
		@ammo['qty']--;
		set_pinv(player(), null, @ammo);
		@ammoslot = pheld_slot();
		play_sound(ploc(), array(sound: 'BLOCK_VAULT_INSERT_ITEM', pitch: 1.4));
		set_peffect(player(), 'slowness', 2, 3, true, false);
		@weaponslot = null;
		@weapon = null;
		foreach(@weaponslot: @weapon in pinv()) {
			if(@weapon && @weapon['name'] === 'SPYGLASS') {
				// Found weaponslot
				set_pcooldown(@weapon['name'], 3000 / 50);
				break();
			}
		}
		if(@weapon) {
			set_timeout(2900, closure(){
				if(ponline(@event['player']) && pmode() !== 'SPECTATOR') {
					play_sound(ploc(), array(sound: 'BLOCK_VAULT_INSERT_ITEM_FAIL', pitch: 1.4));
				}
			});
		}
	}

	bind('player_toggle_sneak', array(id: @player.'snipersneak'), array(player: @player), @event) {
		if(@event['sneaking']) {
			// get block type starting from the back, sides, finally below player
			@loc = location_shift(ploc(), 'up', 1);
			@loc['pitch'] = 0.0;
			@loc['yaw'] = round(@loc['yaw'] / 90) * 90 + 180;
			@rotation = 0.0;
			@blockLoc = null;
			@occluding = false;

			do {
				// rotates 0, 90, 180, and 270 to get the right block order
				@loc['yaw'] += @rotation;
				@v = get_vector(@loc);
				@blockLoc = @loc[];
				@blockLoc['x'] += @v['x'];
				@blockLoc['z'] += @v['z'];
				@occluding = material_info(get_block(@blockLoc), 'isOccluding');
				@rotation += 90.0;
			} while(!@occluding && @rotation < 360.0)

			if(!@occluding) {
				@blockLoc = ploc();
			}

			// spawn fake blocks
			@block = get_blockdata_string(@blockLoc);
			@loc['yaw'] = 0.0;
			@disguise = spawn_entity('BLOCK_DISPLAY', 2, @loc, closure(@e) {
				set_entity_saves_on_unload(@e, false);
				set_entity_spec(@e, array(blockdata: @block));
				set_display_entity(@e, array(
					viewrange: 128,
					transformation: array(
						scale: array(
							x: 1.0,
							y: 0.1,
							z: 1.0),
						translation: array(
							x: -0.5,
							y: -1.5,
							z: -0.5))));
				add_scoreboard_tag(@e, 'disguise');
			});
			set_entity_rider(puuid(), @disguise[0]);
			set_entity_rider(puuid(), @disguise[1]);
			set_peffect(player(), 'invisibility', 1, -1, true, false);
			foreach(@i: @d in @disguise) {
				set_display_entity(@d, array(
					interpolationduration: 3,
					startinterpolation: 0,
					transformation: array(
						scale: array(
							x: 1.0,
							y: 1.0,
							z: 1.0),
						translation: array(
							x: -0.5,
							y: -0.5 - @i,
							z: -0.5))));
			}
			play_sound(@loc, array(sound: 'ITEM_ARMOR_EQUIP_LEATHER'));
		} else {
			set_peffect(player(), 'invisibility', 0, 0);
			foreach(@entity in get_entity_riders(puuid())) {
				if(has_scoreboard_tag(@entity, 'disguise')) {
					entity_remove(@entity);
				}
			}
		}
	}
	
	bind('player_death', array(id: @player.'sniperdeath', priority: 'HIGHEST'), array(player: @player), @event) {
		foreach(@entity in get_entity_riders(puuid())) {
			if(has_scoreboard_tag(@entity, 'disguise')) {
				entity_remove(@entity);
			}
		}
	}
}

proc _class_powerup(@player) {
	set_pcooldown('SPYGLASS', 0);
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'usesnipeglass');
	unbind(@player.'stopsnipeglass');
	unbind(@player.'reloadsnipeglass');
	unbind(@player.'snipersneak');
	unbind(@player.'sniperdeath');
}
