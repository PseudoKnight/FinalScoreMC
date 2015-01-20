# Armor stand protection
bind(player_interact, null, array('item': 416, 'button': 'right'), @event) {
	if(@event['action'] == 'right_click_block' 
	&& _is_survival_world(@event['world'])
	&& (!sk_can_build(@event['location']) || !sk_region_check_flag(@event['location'], 'mob-spawning'))) {
		cancel();
	}
}

proc _position_degrees(@position, @rotation) {
	@yaw = get_yaw(array(0, 0, 0), @position);
	@yaw -= @rotation;
	if(@yaw < -180) {
		@yaw += 360;
	} else if(@yaw > 180) {
		@yaw -= 360;
	}
	return(@yaw)
}

bind(player_interact_at_entity, null, array('clicked': 'ARMOR_STAND'), @event) {
	if(_is_survival_world(entity_loc(@event['id'])['world']) 
	&& !sk_can_build(entity_loc(@event['id']))) {
		cancel();
		die();
	}
	
	# If right-click with sticks, add arms
	@item = pinv(player(), null);
	@armorstand = entity_spec(@event['id']);
	if(is_null(@item)) {
		if(!@armorstand['visible']) {
			die();
		}
		
		# Check if armor stand is empty
		@equipment = get_mob_equipment(@event['id']);
		foreach(@piece in @equipment) {
			if(!is_null(@piece)) {
				die();
			}
		}

		# If sneaking, go into pose mode
		if(pinfo(player(), 11)) {
			# Get poseable section of armor stand
			@poseable = '';
			if(@event['position']['y'] >= 1.6) {
				@poseable = 'Head';
			} else if(@event['position']['y'] >= 0.9) {
				@poseable = 'Torso';
				if(@armorstand['arms']) {
					@deg = _position_degrees(@event['position'], entity_loc(@event['id'])['yaw']);
					if(@deg > 35 && @deg < 145) {
						@poseable = 'ArmRight';
					} else if(@deg < -35 && @deg > -145) {
						@poseable = 'ArmLeft';
					}
				}
			} else if(@event['position']['y'] >= 0.55) {
				@deg = _position_degrees(@event['position'], entity_loc(@event['id'])['yaw']);
				if(@deg > 0) {
					@poseable = 'LegRight';
				} else {
					@poseable = 'LegLeft';
				}
			} else {
				@poseable = 'armorstand';
			}
			
			# Start posing
			if(@poseable == 'armorstand') {
				msg(color(6).'Rotating Armor Stand.');
				
				@dir = pfacing();
				@eloc = entity_loc(@event['id']);
				@newloc = @eloc[];
				
				@taskid = set_interval(100, closure(){
					if(!pinfo(player(), 11) || !entity_exists(@event['id'])) {
						clear_task();
						return();
					}
					
					@newdir = pfacing();
					@dyaw = (@dir[0] - @newdir[0]) * 2.5;
					@newloc['yaw'] = @eloc['yaw'] + @dyaw;
					set_entity_loc(@event['id'], @newloc);
				});
				
			} else {
				msg(color(6).'Posing '.@poseable.'.');
				
				@dir = pfacing();
				@poseable = 'pose'.@poseable;
				@newspec = array('poses': array());
				@newspec['poses'][@poseable] = @armorstand['poses'][@poseable][];
				
				@taskid = set_interval(100, closure(){
					if(!ponline(player()) || !pinfo(player(), 11) || !entity_exists(@event['id'])) {
						clear_task();
						return();
					}
					
					@newdir = pfacing();
					@dyaw = to_radians(@newdir[0] - @dir[0]) * 2.5;
					@dpitch = to_radians(@newdir[1] - @dir[1]) * 2.5;
					@newspec['poses'][@poseable]['x'] = @armorstand['poses'][@poseable]['x'] + @dpitch;
					@newspec['poses'][@poseable]['z'] = @armorstand['poses'][@poseable]['z'] + @dyaw;
					set_entity_spec(@event['id'], @newspec);
				});
			}
		
		# If not sneaking, move armor stand.
		} else {
			msg(color(6).'Moving Armor Stand. Sneak to drop.');
			set_entity_rider(pinfo(player(), 13), @event['id']);
			
			bind(player_toggle_sneak, null, array('player': player()), @event) {
				set_entity_rider(pinfo(player(), 13), null);
				unbind();
			}
		}
		
	} else {
		switch(@item['type']) {
			case 44:
				if(pworld() == 'dev') {
					msg(color(6).'Toggled baseplate for armor stand.');
					set_entity_spec(@event['id'], array('baseplate': if(@armorstand['baseplate'], false, true)));
					cancel();
				}
				
			case 280:
				if(@item['qty'] >= 2 && !@armorstand['arms']) {
					set_entity_spec(@event['id'], array('arms': true));
					@item['qty'] -= 2;
					set_pinv(player(), array('null': if(@item['qty'] > 0, @item, null)));
					cancel();
				}
			
			case 288:
				if(pworld() == 'dev') {
					msg(color(6).'Toggled gravity for armor stand.');
					set_entity_spec(@event['id'], array('gravity': if(@armorstand['gravity'], false, true)));
					cancel();
				}
				
			case 375:
				if(pworld() == 'dev') {
					msg(color(6).'Toggled visibility for armor stand.');
					set_entity_spec(@event['id'], array('visible': if(@armorstand['visible'], false, true)));
					cancel();
				}
			
			case 416:
				if(pworld() == 'dev') {
					msg(color(6).'Toggled size for armor stand.');
					set_entity_spec(@event['id'], array('small': if(@armorstand['small'], false, true)));
					cancel();
				}
			
		}
	}
}

bind(entity_damage, null, array('type': 'ARMOR_STAND'), @event) {
	@damager = '';
	if(array_index_exists(@event, 'damager')) {
		@damager = @event['damager'];
	} else if(array_index_exists(@event, 'shooter')) {
		@damager = @event['shooter'];
	}
	
	if(@damager == '' || is_numeric(@damager)) {
		die();
	}
	
	if(_is_survival_world(@event['world']) 
	&& !sk_can_build(@damager, @event['location'])) {
		cancel();
		
	} else if(entity_spec(@event['id'])['arms']) {
		cancel();
		@weapon = get_mob_equipment(@event['id'])['weapon'];
		@loc = entity_loc(@event['id']);
		if(!is_null(@weapon)) {
			drop_item(@loc, @weapon);
			set_mob_equipment(@event['id'], array('weapon': null));
		}
		drop_item(@loc, array('type': 280, 'qty': 2));
		set_entity_spec(@event['id'], array('arms': false));
	}
}