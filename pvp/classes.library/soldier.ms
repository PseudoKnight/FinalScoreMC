switch(@action) {
case 'load':
	@damaged = array();
	bind(entity_damage, array('id': @player.'soldierdmg'), array('type': 'PLAYER'), @e, @damaged, @shooter = @player) {
		if(@e['cause'] == 'PROJECTILE'
		&& @e['shooter'] == @shooter) {
			if(@damaged && @damaged[0] == @e['player']) {
				@damaged[1] += 1.0;
			} else {
				@damaged[0] = @e['player'];
				@damaged[1] = 2;
			}
			modify_event('amount', @damaged[1]);
		}
	}

	bind(player_interact, array('id': @player.'soldiershoot'), array('player': @player, 'item': 291), @e) {
		if(pinfo(player(), 6) != @e['item']){
			die();
		}
		@item = pinv(player(), null);
		if(@item['data'] >= 128, die());
		@slot = pheld_slot();

		proc _shoot() {
			// get new location so that the egg does not hit the shooting player
			@dir = _get_vector(pfacing());
			@loc = ploc();
			@loc['x'] += @dir['x'];
			@loc['y'] += 2.2 + @dir['y'];
			@loc['z'] += @dir['z'];

			@bullet = shoot_projectile(player(), 'EGG');
			@v = entity_velocity(@bullet);
			set_entity_loc(@bullet, @loc);
			set_entity_velocity(@bullet, array(@v['x'] * 2.3, @v['y'] * 2.3, @v['z'] * 2.3));
			play_sound(ploc(), array('sound': 'FIREWORK_BLAST', 'pitch': 0.6, 'volume': 2));
		}

		_shoot();
		set_timeout(50, closure(){
			@item['data'] += 8;
			@inv = associative_array();
			@inv[@slot] = @item;
			set_pinv(player(), @inv);
			_shoot();
		});
	}

	bind(player_interact, array('id': @player.'soldierreload'), array('player': @player, 'item': 265), @e, @damaged) {
		if(pinfo(player(), 6) != @e['item']){
			die();
		}
		if(@damaged) {
			array_remove(@damaged, 0);
		}
		@item = pinv(player(), null);
		set_pinv(player(), array(null: null));
		@slot = pheld_slot();
		play_sound(ploc(), array('sound': 'DOOR_OPEN', 'pitch': 2));
		set_timeout(1000, closure(){
			if(ponline(@e['player']) && phealth() > 0) {
				@newitem = pinv(player(), @slot);
				if(!is_null(@newitem) && @newitem['type'] == 265) {
					@item['qty'] = @newitem['qty'] + @item['qty'] - 1;
				} else {
					@item['qty'] -= 1;
				}
				@inv = associative_array();
				if(@item['qty'] > 0) {
					@inv[@slot] = @item;
				}
				@inv[0] = array('type': 291, 'data': 0, 'meta': array('display': 'Machine Gun'));
				set_pinv(player(), @inv);
				play_sound(ploc(), array('sound': 'DOOR_CLOSE', 'pitch': 2))
			}
		});
	}

	bind(player_interact, array('id': @player.'grenade'), array('player': @player, 'item': 273), @e) {
		if(!ptake_item(player(), 273, 1)) {
			die();
		}
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
		set_timeout(4000, closure(){
			try {
				explosion(entity_loc(@armorStand), 3, true);
				entity_remove(@armorStand);
			} catch(BadEntityException @ex) {
				// grenade no longer exists
			}
		});
	}

case 'unload':
	unbind(@player.'soldierdmg');
	unbind(@player.'soldiershoot');
	unbind(@player.'soldierreload');
	unbind(@player.'grenade');
}
