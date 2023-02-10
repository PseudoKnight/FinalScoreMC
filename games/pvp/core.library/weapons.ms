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
	@range = array_get(@ray, 'range', 112);
	@raySize = array_get(@ray, 'raySize', 0.0);
	@inaccuracy = array_get(@ray, 'inaccuracy', 0.0);
	
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
	
	if(@trace['hitblock'] && array_index_exists(@effects, 'hitparticle')) {
		spawn_particle(@location, array(particle: @effects['hitparticle'], count: 8, speed: 0.05));
	}
	if(@entities) {
		foreach(@entity in @entities) {
			if(is_entity_living(@entity['uuid'])
			&& array_contains(sk_regions_at(@entity['location']), @pvp['arena']['region'])
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
					spawn_particle(@entity['location'], array(particle: @effects['hitparticle'], count: 4, speed: 0.05));
				}
			}
		}
	}
	
	if(array_index_exists(@effects, 'tracer')) {
		@distance = distance(@origin, @location);
		@maxParticles = max(ceil(@distance), 20);
		@distance /= @maxParticles;
		@origin['y'] -= if(get_entity_gliding(@damager), 1.54, 0.30); // adjust to gun height for visibility
		@particles = 0;
		while(@particles++ <= @maxParticles) {
			@origin = location_shift(@origin, @location, @distance);
			spawn_particle(@origin, @effects['tracer']);
		}
	}
	
	return(@players);
}
