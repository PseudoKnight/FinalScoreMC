proc _rule_load(@binds, @value) {
	proc _weapon_cooldown(@player, @time, @type, @onCooldown, @remove = 1) {
		@item = pinv(@player, null);
		@item['qty'] -= @remove;
		if(@item['qty'] == 0) {
			set_pinv(@player, null, null);
		} else {
			if(!@type) {
				set_pinv(@player, null, null);
			} else {
				@newItem = @item[];
				@newItem['name'] = @type;
				set_pinv(@player, null, @newItem);
			}
			@slot = pheld_slot(@player);
			set_timeout(@time, closure(){
				try {
					@newItem = pinv(@player, @slot);
					if(!@type || (@newItem && @newItem['name'] == @type)) {
						set_pinv(@player, @slot, @item);
						if(is_closure(@onCooldown)) {
							execute(@onCooldown);
						}
					}
				} catch(PlayerOfflineException @ex) {
					// too impatient to reload
				}
			});
		}
	}

	@binds[] = 'shard-mega';
	bind('world_changed', array('id': 'shard-mega', 'priority': 'LOW'), array('to': 'shard'), @event) {
		queue_push(closure(){
			pgive_item(player(), array('name': 'TNT', 'qty': 64));
			pgive_item(player(), array('name': 'FIRE_CHARGE', 'qty': 64));
			pgive_item(player(), array('name': 'FLINT_AND_STEEL'));
		}, 'shard');
	}

	@binds[] = 'shard-fireball';
	bind('player_interact', array('id': 'shard-fireball'), array('itemname': 'FIRE_CHARGE', 'block': null), @event) {
		if(pworld() == 'shard') {
			cancel();
			@entity = shoot_projectile(player(), 'SMALL_FIREBALL');
			play_sound(ploc(), array('sound': 'ENTITY_GHAST_SHOOT', 'volume': 2));
			_weapon_cooldown(player(), 1000, 'FIREWORK_STAR', closure(){
				play_sound(ploc(), array('sound': 'BLOCK_FIRE_EXTINGUISH', 'pitch': 1.5));
			});
		}
	}
}
