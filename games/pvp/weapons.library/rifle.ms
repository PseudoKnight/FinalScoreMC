proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'IRON_INGOT'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @event['item']['name']){
			die();
		}
		@ammo = pinv(player(), null);
		@ammo['qty']--;
		set_pinv(player(), null, null);
		@ammoslot = pheld_slot();
		play_sound(ploc(), array(sound: 'BLOCK_WOODEN_DOOR_OPEN', pitch: 2));
		@weaponslot = null;
		@weapon = null;
		foreach(@weaponslot: @weapon in pinv()) {
			if(@weapon && @weapon['name'] == 'STONE_HOE') {
				// Found weaponslot
				set_pcooldown(@weapon['name'], 2000 / 50);
				break();
			}
		}
		if(@weapon) {
			set_timeout(2000, closure(){
				if(ponline(@event['player']) && pmode() != 'SPECTATOR') {
					@inv = pinv();
					if(!is_null(@inv[@ammoslot]) && @inv[@ammoslot]['name'] == 'IRON_INGOT') {
						@inv[@ammoslot]['qty'] += @ammo['qty'];
					} else {
						@inv[@ammoslot] = @ammo;
					}
					@weapon['meta']['damage'] = 10;
					@inv[@weaponslot] = @weapon;
					set_pinv(player(), @inv);
					play_sound(ploc(), array(sound: 'BLOCK_WOODEN_DOOR_CLOSE', pitch: 2));
				}
			});
		}
	}

	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'STONE_HOE'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @event['item']['name']){
			die();
		}
		@item = pinv(player(), null);
		if(!@item['meta'] || @item['meta']['display'] != 'Rifle' || @item['meta']['damage'] >= 130 || pcooldown(@item['name'])) {
			die();
		}
		
		@item['meta']['damage'] += 8;
		set_pinv(player(), null, @item);
		
		_weapon_hit_scan(player(), associative_array(), 1.7, array(tracer: 'SUSPENDED_DEPTH', hitparticle: 'SMOKE_LARGE'), @pvp);
		play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST', pitch: 0.7, volume: 3));
		set_timeout(50, closure(){
			_weapon_hit_scan(player(), associative_array(), 3.4, array(tracer: 'SUSPENDED_DEPTH', hitparticle: 'SMOKE_LARGE'), @pvp);
			play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST', pitch: 0.7, volume: 3));
		});
	}
}
