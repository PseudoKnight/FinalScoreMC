bind(player_interact_at_entity, null, array('clicked': 'ARMOR_STAND'), @event) {
	if(!sk_can_build(entity_loc(@event['id']))) {
		cancel();
		die();
	}
	
	@item = pinv(player(), null);
	@armorstand = entity_spec(@event['id']);
	if(is_null(@item)) {
		if(!@armorstand['visible']) {
			die();
		}
		
		@posing = import(player().'posing');
		if(@posing) {
			die();
		}

		# If sneaking, go into pose mode
		if(pinfo(player(), 11)) {
		
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
		
			export(player().'posing', true);
			cancel();
			
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
				
				@taskid = set_interval(50, closure(){
					if(!pinfo(player(), 11) || !entity_exists(@event['id'])) {
						clear_task();
						export(player().'posing', null);
						return();
					}
					
					@newdir = pfacing();
					
					@yawdiff = @newdir[0] - @dir[0];
					if(@yawdiff > 180) {
						@yawdiff -= 360;
					} else if(@yawdiff < -180) {
						@yawdiff += 360;
					}
					
					@dyaw = @yawdiff * 2.5;
					@newloc['yaw'] = @eloc['yaw'] - @dyaw;
					set_entity_loc(@event['id'], @newloc);
				});
				
			} else if(@poseable == 'Torso') {
				msg(color(6).'Adjusting Armor Stand position.');
			
				@eloc = entity_loc(@event['id']);
				@originalYaw = @eloc['yaw'];
				@dist = _distance(@eloc, _relative(ploc(), 'up'));
				set_entity_spec(@event['id'], array('gravity': false));
				
				set_interval(50, closure(){
					if(!ponline(player()) || !pinfo(player(), 11) || !entity_exists(@event['id'])) {
						try(set_entity_spec(@event['id'], array('gravity': @armorstand['gravity'])));
						clear_task();
						export(player().'posing', null);
						return();
					}
					
					@eloc = _relative(ploc(), 'up', 1.3);
					@yaw = to_radians(@eloc['yaw'] + 90);
					@pitch = to_radians(0 - @eloc['pitch']);
					@eloc['x'] += @dist * cos(@yaw) * cos(@pitch);
					@eloc['y'] += @dist * sin(@pitch);
					@eloc['z'] += @dist * sin(@yaw) * cos(@pitch);
					@eloc['yaw'] = @originalYaw;
					set_entity_loc(@event['id'], @eloc);
				});
				
			} else {
				msg(color(6).'Posing '.@poseable.'.');
				
				@dir = pfacing();
				@eloc = entity_loc(@event['id']);
				@dist = _distance(@eloc, ploc());
				@poseable = 'pose'.@poseable;
				@newspec = associative_array('poses': array());
				@newspec['poses'][@poseable] = @armorstand['poses'][@poseable][];
				
				set_interval(50, closure(){
					if(!ponline(player()) || !pinfo(player(), 11) || !entity_exists(@event['id'])) {
						clear_task();
						export(player().'posing', null);
						return();
					}
					
					@newdir = pfacing();
					@newdist = _distance(@eloc, ploc());
					
					@yawdiff = @newdir[0] - @dir[0];
					if(@yawdiff > 180) {
						@yawdiff -= 360;
					} else if(@yawdiff < -180) {
						@yawdiff += 360;
					}
					
					@dyaw = to_radians(@yawdiff) * 2.5;
					@ddist = to_radians(@newdist - @dist) * 100;
					@dpitch = to_radians(@newdir[1] - @dir[1]) * 2.5;
					if(@poseable == 'poseHead') {
						@newspec['poses'][@poseable]['x'] = @armorstand['poses'][@poseable]['x'] + @dpitch;
						@newspec['poses'][@poseable]['y'] = @armorstand['poses'][@poseable]['y'] + @ddist;
						@newspec['poses'][@poseable]['z'] = @armorstand['poses'][@poseable]['z'] + @dyaw;
					} else {
						@newspec['poses'][@poseable]['x'] = @armorstand['poses'][@poseable]['x'] - @dpitch;
						@newspec['poses'][@poseable]['y'] = @armorstand['poses'][@poseable]['y'] + @ddist;
						@newspec['poses'][@poseable]['z'] = @armorstand['poses'][@poseable]['z'] - @dyaw;
					}
					set_entity_spec(@event['id'], @newspec);
				});
			}
		}
		
	} else {
		switch(@item['type']) {				
			case 280: # 2 sticks attaches arms
				if(@item['qty'] >= 2 && !@armorstand['arms']) {
					set_entity_spec(@event['id'], array('arms': true));
					@item['qty'] -= 2;
					set_pinv(player(), array(null: if(@item['qty'] > 0, @item, null)));
					cancel();
				}
			
			case 288: # feather toggles gravity
				if(!_is_survival_world(pworld())) {
					msg(color(6).'Toggled gravity for armor stand.');
					set_entity_spec(@event['id'], array('gravity': if(@armorstand['gravity'], false, true)));
					cancel();
				}
				
			case 375: # spider eye toggles visibility
				if(!_is_survival_world(pworld())) {
					msg(color(6).'Toggled visibility for armor stand.');
					set_entity_spec(@event['id'], array('visible': if(@armorstand['visible'], false, true)));
					cancel();
				}
			
			case 416: # armor stand toggles size
				if(!_is_survival_world(pworld())) {
					msg(color(6).'Toggled size for armor stand.');
					set_entity_spec(@event['id'], array('small': if(@armorstand['small'], false, true)));
					cancel();
				}
				
			case 420: # lead carries armor stand
				if(!pinfo(player(), 11)) {
					cancel();
					msg(color(6).'Moving Armor Stand. Sneak to drop.');
					set_entity_rider(puuid(), @event['id']);
					
					bind(player_toggle_sneak, null, array('player': player()), @event) {
						set_entity_rider(puuid(), null);
						unbind();
					}
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
	
	if(@damager == '' || !ponline(@damager)) {
		die();
	}
	
	if(sk_can_build(@damager, @event['location'])) {
		@armorstand = entity_spec(@event['id']);
		if(@armorstand['arms']) {
			cancel();
			@weapon = get_mob_equipment(@event['id'])['weapon'];
			@loc = entity_loc(@event['id']);
			if(!is_null(@weapon)) {
				drop_item(@loc, @weapon);
				set_mob_equipment(@event['id'], array('weapon': null));
			}
			drop_item(@loc, array('type': 280, 'qty': 2));
			set_entity_spec(@event['id'], array('arms': false));
		} else if(@armorstand['baseplate']) {
			cancel();
			@item = drop_item(entity_loc(@event['id']), array('type': 44));
			set_entity_spec(@item, array('pickupdelay': 60));
			set_entity_spec(@event['id'], array('baseplate': false));
			set_timeout(2000, closure(){
				try(entity_remove(@item));
			});
		}
	}
}