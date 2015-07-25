switch(@action) {
case 'load':
	bind(entity_damage, array('id': player().'soldierdmg'), array('type': 'PLAYER'), @e, @shooter = @player) {
		if(@e['cause'] == 'PROJECTILE'
		&& @e['shooter'] == @shooter) {
			modify_event('amount', 2);
		}
	}
	
	bind(player_interact, array('id': player().'soldiershoot'), array('player': @player, 'item': 291), @e) {
		@item = pinv(player(), null);
		if(@item['data'] >= 128, die());
		@bullet = shoot_projectile(@e['player'], 'EGG');
		@v = entity_velocity(@bullet);
		set_entity_velocity(@bullet, array(@v['x'] * 2.9, @v['y'] * 2.9, @v['z'] * 2.9));
		play_sound(ploc(), array('sound': 'FIREWORK_LARGE_BLAST', 'pitch': 1.5, 'volume': 2));
		@slot = pinfo(player(), 15);
		set_timeout(50, closure(){
			@item['data'] += 8;
			@inv = array();
			@inv[@slot] = @item;
			set_pinv(player(), @inv);
			@bullet = shoot_projectile(@e['player'], 'EGG');
			@v = entity_velocity(@bullet);
			set_entity_velocity(@bullet, array(@v['x'] * 2.9, @v['y'] * 2.9, @v['z'] * 2.9));
			play_sound(ploc(), array('sound': 'FIREWORK_LARGE_BLAST', 'pitch': 1.5, 'volume': 2));
		});
	}
	
	bind(player_interact, array('id': player().'soldierreload'), array('player': @player, 'item': 265), @e) {
		@item = pinv(player(), null);
		set_pinv(player(), array('null': null));
		@slot = pinfo(player(), 15);
		play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
		set_timeout(1000, closure(){
			@newitem = pinv(player(), @slot);
			if(!is_null(@newitem) && @newitem['type'] == 265) {
				@item['qty'] = @newitem['qty'] + @item['qty'] - 1;
			} else {
				@item['qty'] -= 1;
			}
			@inv = array();
			if(@item['qty'] > 0) {
				@inv[@slot] = @item;
			}
			@inv[0] = array('type': 291, 'data': 0, 'meta': array('display': 'Machine Gun'));
			set_pinv(player(), @inv);
			play_sound(ploc(), array('sound': 'DOOR_CLOSE', 'pitch': 2))
		});
	}
	
	bind(player_interact, array('id': player().'grenade'), array('player': @player, 'item': 273), @e) {
		ptake_item(player(), 273, 1);
		@loc = _relative(ploc(), 'up', 2);
		@armorStand = spawn_entity('ARMOR_STAND', 1, @loc)[0];
		set_entity_spec(@armorStand, array('visible': false, 'small': true, 'arms': true));
		set_mob_equipment(@armorStand, array('WEAPON': array('type': 273)));
		@loc['yaw'] = @loc['yaw'] + 90;
		@loc['pitch'] = 0 - @loc['pitch'];
		@x = 1.40 * cos(to_radians(@loc['yaw'])) * cos(to_radians(@loc['pitch']));
		@y = max((1.40 * sin(to_radians(@loc['pitch']))) + 0.2, 0.2);
		@z = 1.40 * sin(to_radians(@loc['yaw'])) * cos(to_radians(@loc['pitch']));
		set_entity_velocity(@armorStand, array(@x, @y, @z));
		play_sound(@loc, array('sound': 'IRONGOLEM_THROW'));
		set_timeout(5000, closure(){
			if(entity_exists(@armorStand)) {
				@weapon = get_mob_equipment(@armorStand)['weapon'];
				if(!is_null(@weapon) && @weapon['type'] == 273) {
					explosion(entity_loc(@armorStand), 3, true);
				}
				try(entity_remove(@armorStand));
			}
		});
	}
case 'unload':
	unbind(player().'soldierdmg');
	unbind(player().'soldiershoot'); 
	unbind(player().'soldierreload'); 
	unbind(player().'grenade');
}