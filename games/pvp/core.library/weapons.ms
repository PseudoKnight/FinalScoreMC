include_dir('../weapons.library');

proc _weapon_cooldown(@player, @time, @type, @onCooldown, @remove = 1) {
	@item = pinv(@player, null);
	@item['qty'] -= @remove;
	if(@item['qty'] == 0) {
		set_pinv(@player, null, null);
	} else {
		if(@type == null) {
			set_pinv(@player, null, null);
		} else {
			@newItem = @item[];
			@newItem['name'] = @type;
			if(@newItem['meta']) {
				@newItem['meta']['damage'] = 0;
			}
			set_pinv(@player, null, @newItem);
			set_pcooldown(@player, @type, @time / 50);
		}
		@slot = pheld_slot(@player);
		set_timeout(@time, closure(){
			try {
				@newItem = pinv(@player, @slot);
				if(@type == null || (!is_null(@newItem)
				&& @newItem['name'] == @type)) {
					set_pinv(@player, @slot, @item);
					if(is_closure(@onCooldown)) {
						execute(@onCooldown);
					}
				}
			} catch(PlayerOfflineException @ex) {
				// gun safety failure
			}
		});
	}
}

proc _weapon_hit_scan(@player, @ray, @damage, @effects, @pvp){
	@damager = puuid(@player);
	@range = 112;
	@raySize = 0.0;
	@inaccuracy = 0.0;
	if(@ray) {
		if(array_index_exists(@ray, 'range')) {
			@range = @ray['range'];
		}
		if(array_index_exists(@ray, 'raySize')) {
			@raySize = @ray['raySize'];
		}
		if(array_index_exists(@ray, 'inaccuracy')) {
			@inaccuracy = @ray['inaccuracy'];
		}
	}
	
	@hitsound = 'ENTITY_ARROW_HIT_PLAYER';
	if(array_index_exists(@effects, 'hitsound')) {
		@hitsound = @effects['hitsound'];
	}
	
	@trace = null;
	if(!@inaccuracy) {
		@trace = ray_trace(@player, @range, @raySize);
	} else {
		@loc = location_shift(ploc(), 'up', if(psneaking(), 2.27, 2.62));
		@loc['yaw'] += rand() * @inaccuracy * 2 - @inaccuracy;
		@loc['pitch'] += rand() * @inaccuracy * 2 - @inaccuracy;
		@trace = ray_trace(@player, @loc, @range, @raySize);
	}
	@origin = @trace['origin'];
	@location = @trace['location'];
	@entities = @trace['entities'];
	@players = array();
	@spec = array_merge(array_keys(@pvp['players']), @pvp['spectators']);

	if(@trace['hitblock'] && array_index_exists(@effects, 'hitparticle')) {
		spawn_particle(@location, array(particle: @effects['hitparticle'], count: 8, speed: 0.05, force: true), @spec);
	}
	if(@entities) {
		foreach(@entity in @entities) {
			if(is_entity_living(@entity['uuid'])
			&& sk_region_contains(@pvp['arena']['region'], @entity['location'])
			&& @entity['uuid'] != pvehicle(@player)) {
				try {
					@player = player(@entity['uuid']);
					if(!array_index_exists(@pvp['players'], @player) || pmode(@player) == 'SPECTATOR') {
						continue();
					}
					if(@hitsound) {
						if(is_array(@hitsound)) {
							play_sound(@origin, @hitsound, player());
						} else {
							play_sound(@origin, array(sound: @hitsound), player());
						}
					}
					@players[] = @player;
				} catch(PlayerOfflineException @ex) {
					// not a player, but let us still kill it
				}
				if(!is_null(@damage)) {
					damage_entity(@entity['uuid'], @damage, @damager);
				}
				if(array_index_exists(@effects, 'hitparticle')) {
					spawn_particle(@entity['location'], array(particle: @effects['hitparticle'], count: 4, speed: 0.05, force: true), @spec);
				}
			}
		}
	}

	@origin['y'] -= if(get_entity_gliding(@damager), 1.54, 0.58); // adjust to gun height for visibility
	@distance = distance(@origin, @location);

	// create display entity tracer line
	if(@raySize && array_index_exists(@effects, 'display')) {
		// remove yaw/pitch from origin location so that display entity does not inherit them
		@yaw = array_remove(@origin, 'yaw');
		array_remove(@origin, 'pitch'); // pitch will be adjusted for new starting height
		@pitch = get_pitch(@origin, @location);

		// get xz translation
		@v = get_vector(array(yaw: @yaw + 90, pitch: 0.0), @raySize);

		// get quaternion rotation
		@y = -to_radians(@yaw) * 0.5;
		@p = to_radians(@pitch) * 0.5;
		@leftRotation = array(
			w: cos(@p) * cos(@y),
			x: sin(@p) * cos(@y),
			y: cos(@p) * sin(@y),
			z: -sin(@p) * sin(@y),
		);

		@line = spawn_entity('BLOCK_DISPLAY', 1, @origin, closure(@line) {
			set_entity_saves_on_unload(@line, false);
			set_entity_spec(@line, array(blockdata: @effects['display']));
			set_display_entity(@line, array(
				brightness: 15,
				transformation: array(
					translation: array(
						x: @v['x'],
						y: -@raySize,
						z: @v['z']),
					scale: array(
						x: @raySize * 2,
						y: @raySize * 2,
						z: @distance),
					leftRotation: @leftRotation)));
		})[0];
		set_timeout(50, closure(){
			// shrink display entity
			set_display_entity(@line, array(
				interpolationduration: 8,
				startinterpolation: 0,
				transformation: array(
					translation: array(
						x: 0.0,
						y: 0.0,
						z: 0.0),
					scale: array(
						x: 0.0,
						y: 0.0,
						z: @distance))));
			set_timeout(400, closure(){
				try(entity_remove(@line))
			});
		});
	}

	if(array_index_exists(@effects, 'tracer')) {
		if(!is_array(@effects['tracer'])) {
			@effects['tracer'] = array(particle: @effects['tracer']);
		}
		@effects['tracer']['force'] = true;
		@distanceProgress = 1.0;
		while(@distanceProgress <= @distance) {
			@particleLoc = location_shift(@origin, @location, @distanceProgress);
			spawn_particle(@particleLoc, @effects['tracer'], @spec);
			@distanceProgress += 0.5 + rand() / 2;
		}
	}

	return(@players);
}
