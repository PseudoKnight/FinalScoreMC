proc _class_load(@player, @pvp) {
	@horseHealth = array(100.0);
	bind('player_interact', array(id: @player.'revolver'), array(player: @player, itemname: 'IRON_HORSE_ARMOR', button: 'right'), @event, @pvp){
		if(!pcooldown('IRON_HORSE_ARMOR')) {
			@item = pinv(player(), null);
			if(@item['qty'] == 1) {
				set_pcooldown('IRON_HORSE_ARMOR', 1440000);
			} else {
				@item['qty']--;
				set_pinv(player(), null, @item);
			}
			play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST', pitch: 0.9, volume: 2));
			play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST_FAR', pitch: 0.5, volume: 2));
			@inaccuracy = 10;
			if(!pvehicle() && !psprinting()) {
				@inaccuracy = 5;
				if(psneaking()) {
					@inaccuracy = 2.5;
				}
			}
			_weapon_hit_scan(player(), array(range: 16, raySize: 0.2, inaccuracy: @inaccuracy), 4.2, array(tracer: 'SUSPENDED_DEPTH', hitparticle: 'SMOKE_LARGE'), @pvp);
		}
	}
	bind('player_interact', array(id: @player.'round'), array(player: @player, itemname: 'POLISHED_BLACKSTONE_BUTTON', button: 'right'), @event){
		@item = pinv(player(), 0);
		if(@item['qty'] < 6) {
			if(pcooldown('IRON_HORSE_ARMOR')) {
				set_pcooldown('IRON_HORSE_ARMOR', 0);
			} else {
				@item['qty']++;
				set_pinv(player(), 0, @item);
			}
			@ammo = pinv(player(), null);
			@ammo['qty']--;
			set_pinv(player(), null, @ammo);
			if(@item['qty'] == 6) {
				play_sound(ploc(), array(sound: 'BLOCK_CHAIN_HIT', pitch: 1.5));
			} else {
				play_sound(ploc(), array(sound: 'BLOCK_CHAIN_HIT', pitch: 2.0));
			}
		}
	}
	bind('player_interact', array(id: @player.'lassothrow'), array(player: @player, itemname: 'LEAD', button: 'right'), @event, @pvp){
		if(!pcooldown('LEAD')) {
			set_pcooldown('LEAD', 40);
			play_sound(ploc(), array(sound: 'ITEM_ARMOR_EQUIP_LEATHER'));
			@slot = pheld_slot();
			@item = pinv(player(), @slot);
			set_pinv(player(), @slot, null);
			@cat = spawn_entity('CAT', 1, location_shift(ploc(), 'up', 3.1), closure(@cat) {
				set_entity_silent(@cat, true);
				set_mob_effect(@cat, 'INVISIBILITY', 0, 9, true, false);
				set_leashholder(@cat, puuid());
			})[0];
			@vector = get_vector(ploc(), 1.1);
			@timer = array(40);
			set_interval(50, closure(){
				if(!array_index_exists(@pvp['players'], player()) || pmode() != 'ADVENTURE') {
					clear_task();
					try(entity_remove(@cat))
					die();
				}
				try {
					if(entity_grounded(@cat) || @timer[0]-- <= 0) {
						entity_remove(@cat);
						clear_task();
						set_pinv(player(), @slot, @item);
						die();
					}
					@entity = null;
					foreach(@e in entities_in_radius(entity_loc(@cat), 4)) {
						if(@e != puuid()
						&& @e != pvehicle()
						&& @e != @cat
						&& (entity_type(@e) != 'PLAYER' || pmode(@e) != 'SPECTATOR')) {
							@dist = distance(location_shift(entity_loc(@e), 'up'), entity_loc(@cat));
							if(@dist < 2.5) {
								@entity = @e;
								clear_task();
								break();
							}
						}
					}
					if(@entity) {
						@loc1 = entity_loc(@entity);
						play_sound(@loc1, array(sound: 'ENTITY_HORSE_BREATHE', pitch: 1.7, volume: 3));
						@loc2 = entity_loc(puuid());
						@dist = distance(@loc1, @loc2) / 2;
						if(@dist > 0) {
							set_entity_velocity(@entity, array(
								(@loc2['x'] - @loc1['x']) / @dist,
								max((@loc2['y'] - @loc1['y']) / @dist, 0.2),
								(@loc2['z'] - @loc1['z']) / @dist,
							));
						}
						set_pinv(player(), @slot, @item);
						set_leashholder(@cat, null);
						entity_remove(@cat);

					} else {
						set_entity_velocity(@cat, array(
							@vector['x'],
							@vector['y'] - 1.0 + (@timer[0] / 40),
							@vector['z'],
						));
					}
				} catch(BadEntityException @ex) {
					clear_task();
				}
			});
		}
	}
	bind('player_interact_entity', array(id: @player.'cat'), array(clicked: 'CAT'), @event, @player){
		if(@player == @event['player']) {
			cancel();
		}
	}
	bind('vehicle_leave', array(id: @player.'dismount'), array(vehicletype: 'HORSE'), @event, @player) {
		if(@player == @event['player']) {
			@horseHealth = 100.0;
			try(@horseHealth = get_entity_health(@event['vehicle']))
			set_timeout(1, closure(){
				try {
					entity_remove(@event['vehicle']);
					set_pcooldown(@player, 'HORSE_SPAWN_EGG', 2000 / 50);
					set_pinv(@player, 3, array(name: 'HORSE_SPAWN_EGG', meta: array(display: 'Critter', lore: array(@horseHealth))));
				} catch(BadEntityException @e) {}
			});
		}
	}
	bind('player_interact', array(id: @player.'mount', priority: 'HIGHEST'), array(player: @player, itemname: 'HORSE_SPAWN_EGG', button: 'right'), @event, @horseHealth){
		cancel();
		consume();
		if(!array_index_exists(@event, 'location') || pcooldown('HORSE_SPAWN_EGG')) {
			die();
		}
		@item = pinv(player(), null);
		set_pinv(player(), null, null);
		@loc = @event['location'];
		if(get_block_info(@loc)['solid']) {
			@loc = location_shift(@loc, @event['facing']);
		}
		@loc['x'] += 0.5;
		@loc['z'] += 0.5;
		_spawn_entity('critter', @loc, null, closure(@horse) {
			set_entity_health(@horse, @item['meta']['lore'][0]);
			add_scoreboard_tag(@horse, 'nodrops');
		});
		@effectLoc = location_shift(@loc, 'up');
		play_sound(@effectLoc, array(sound: 'ENTITY_HORSE_AMBIENT'));
		spawn_particle(@effectLoc, array(particle: 'CLOUD', count: 10, xoffset: 0.4, zoffset: 0.4, yoffset: 0.4));
	}
}

proc _class_powerup(@player) {
	@vehicle = pvehicle(@player);
	if(@vehicle) {
		set_entity_health(@vehicle, 100);
	} else {
		set_pinv(@player, 3, array(name: 'HORSE_SPAWN_EGG', meta: array(
			display: 'Critter',
			lore: array(100),
		)));
	}
}

proc _class_unload(@player, @pvp) {
	set_pcooldown(@player, 'IRON_HORSE_ARMOR', 0);
	unbind(@player.'revolver');
	unbind(@player.'round');
	unbind(@player.'lassothrow');
	unbind(@player.'cat');
	unbind(@player.'dismount');
	unbind(@player.'mount');
}