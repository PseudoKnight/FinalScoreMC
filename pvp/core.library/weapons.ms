proc _weapon_cooldown(@player, @time, @type, @onCooldown, @remove = 1) {
	@item = pinv(@player, null);
	@item['qty'] -= @remove;
	if(@item['qty'] == 0) {
		set_pinv(@player, array(null: null));
	} else {
		if(@type == null) {
			set_pinv(@player, array(null: null));
		} else {
			@newItem = @item[];
			@newItem['name'] = @type;
			@newItem['data'] = 0;
			set_pinv(@player, array(null: @newItem));
		}
		@slot = pinfo(@player, 15);
		set_timeout(@time, closure(){
			try {
				@newItem = pinv(@player, @slot);
				if(@type == null || (!is_null(@newItem)
				&& @newItem['name'] == @type)) {
					@inv = associative_array();
					@inv[@slot] = @item;
					set_pinv(@player, @inv);
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

proc _hit_scan(@player, @range, @damage, @tracerParticle, @hitParticle, @pvp){
	@damager = puuid(@player);
	@visibleRange = max(64, @range);
	
	@trace = ray_trace(@player, @range);
	@origin = @trace['origin'];
	@location = @trace['location'];
	@entities = @trace['entities'];
	@players = array();
	
	if(@trace['result'] == 'hit') {
		play_effect(@location, @hitParticle, array('particleCount': 8, 'speed': 0.05, 'radius': @visibleRange));
	}
	if(@entities) {
		play_sound(@origin, array('sound': 'SUCCESSFUL_HIT'), player());
		foreach(@entity in @entities) {
			if(is_entity_living(@entity['uuid']) && array_contains(sk_regions_at(@entity['location']), @pvp['arena']['region'])) {
				try {
					@player = player(@entity['uuid']);
					if(!array_index_exists(@pvp['players'], @player)) {
						continue();
					}
					@players[] = @player;
				} catch(PlayerOfflineException @ex) {
					// not a player, but let's still kill it
				}
				if(!is_null(@damage)) {
					damage_entity(@entity['uuid'], @damage, @damager);
				}
				play_effect(@entity['location'], @hitParticle, array('particleCount': 4, 'speed': 0.05));
			}
		}
	}
	
	if(@tracerParticle) {
		@distance = _distance(@origin, @location);
		@maxParticles = min(integer(@distance), 20);
		@distance /= @maxParticles;
		@origin['y'] -= if(get_entity_gliding(@damager), 1.54, 0.30); // adjust to gun height for visibility
		@particles = 0;
		while(@particles++ <= @maxParticles) {
			@origin = location_shift(@origin, @location, @distance);
			play_effect(@origin, @tracerParticle, array('speed': 0, 'radius': @visibleRange));
		}
	}
	
	return(@players);
}
