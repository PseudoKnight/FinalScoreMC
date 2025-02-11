proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'IRON_HOE', hand: 'main_hand'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player())){
			die();
		}
		@slot = pheld_slot();
		@item = pinv(player(), @slot);
		if(!@item['meta'] || @item['meta']['display'] != 'Battle Rifle' || pcooldown(@item['name'])) {
			die();
		}
		
		@currentAmmo = @item['meta']['lore'][0];
		@maxAmmo = @item['meta']['lore'][1];
		
		if(@currentAmmo <= 0) {
			play_sound(ploc(), array(sound: 'UI_BUTTON_CLICK', pitch: 2));
			action_msg(player(), '0 / '.@maxAmmo);
			die();
		}
		
		_weapon_hit_scan(player(), null, 1.29, array(tracer: 'SUSPENDED_DEPTH', hitparticle: 'SMOKE_LARGE'), @pvp);
		play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST', pitch: 0.8, volume: 4));
		action_msg(player(), (--@currentAmmo).' / '.@maxAmmo);
		set_pcooldown(@item['name'], 500 / 50);
		@item['meta']['lore'] = array(@currentAmmo, @maxAmmo);
		set_pinv(player(), @slot, @item);
		set_timeout(50, closure(){
			if(pheld_slot() == @slot) {
				_weapon_hit_scan(player(), null, 2.58, array(tracer: 'SUSPENDED_DEPTH', hitparticle: 'SMOKE_LARGE'), @pvp);
				play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST', pitch: 0.8, volume: 4));
				action_msg(player(), (--@currentAmmo).' / '.@maxAmmo);
				@newitem = pinv(player(), @slot);
				if(@newitem && @newitem['name'] == 'IRON_HOE') {
					@newitem['meta']['lore'] = array(@currentAmmo, @maxAmmo);
					set_pinv(player(), @slot, @newitem);
				}
				set_timeout(50, closure(){
					if(pheld_slot() == @slot) {
						_weapon_hit_scan(player(), null, 3.87, array(tracer: 'SUSPENDED_DEPTH', hitparticle: 'SMOKE_LARGE'), @pvp);
						play_sound(ploc(), array(sound: 'ENTITY_FIREWORK_ROCKET_BLAST', pitch: 0.8, volume: 4));
						action_msg(player(), (--@currentAmmo).' / '.@maxAmmo);
						@newitem = pinv(player(), @slot);
						if(@newitem && @newitem['name'] == 'IRON_HOE') {
							@newitem['meta']['lore'] = array(@currentAmmo, @maxAmmo);
							set_pinv(player(), @slot, @newitem);
						}
						if(@currentAmmo <= 0 && @maxAmmo > 0) {
							play_sound(ploc(), array(sound: 'BLOCK_WOODEN_DOOR_OPEN', pitch: 2));
							set_pcooldown(@item['name'], 1900 / 50);
							set_timeout(1850, closure(){
								play_sound(ploc(), array(sound: 'BLOCK_WOODEN_DOOR_CLOSE', pitch: 2));
								@amount = min(@maxAmmo, 36);
								@currentAmmo = @amount;
								@maxAmmo -= @amount;
								@newitem = pinv(player(), @slot);
								if(@newitem && @newitem['name'] == 'IRON_HOE') {
									@newitem['meta']['lore'] = array(@currentAmmo, @maxAmmo);
									set_pinv(player(), @slot, @newitem);
								}
								if(pheld_slot() == @slot) {
									action_msg(player(), @currentAmmo.' / '.@maxAmmo);
								}
							});
						}
					}
				});
			}
		});
	}
}
