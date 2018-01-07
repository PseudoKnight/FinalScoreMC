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
			@newItem['data'] = 0;
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

proc _weapon_hit_scan(@player, @range, @damage, @tracerParticle, @hitParticle, @pvp){
	@damager = puuid(@player);
	@visibleRange = max(64, @range);
	
	@trace = ray_trace(@player, @range);
	@origin = @trace['origin'];
	@location = @trace['location'];
	@entities = @trace['entities'];
	@players = array();
	
	if(@trace['hitblock']) {
		play_effect(@location, @hitParticle, array('particleCount': 8, 'speed': 0.05, 'radius': @visibleRange));
	}
	if(@entities) {
		foreach(@entity in @entities) {
			if(is_entity_living(@entity['uuid'])
			&& array_contains(sk_regions_at(@entity['location']), @pvp['arena']['region'])) {
				play_sound(@origin, array('sound': 'SUCCESSFUL_HIT'), player());
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
		@maxParticles = min(ceil(@distance), 20);
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
