foreach(@p in all_players()) {
	export(@p.'posing', null);
}

bind(player_interact_at_entity, null, array('clicked': 'ARMOR_STAND'), @event) {
	if(!sk_can_build(entity_loc(@event['id']))) {
		cancel();
		die();
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

	proc _get_poseable(@id, @armorstand, @position) {
		@poseable = 'armorstand';
		@scale = if(@armorstand['small'], 2, 1);
		if(@position['y'] >= 1.6 / @scale) {
			@poseable = 'Head';
		} else if(@position['y'] >= 0.9 / @scale) {
			@poseable = 'Torso';
			if(@armorstand['arms']) {
				@deg = _position_degrees(@position, entity_loc(@id)['yaw']);
				if(@deg > 35 && @deg < 145) {
					@poseable = 'ArmRight';
				} else if(@deg < -35 && @deg > -145) {
					@poseable = 'ArmLeft';
				}
			}
		} else if(@position['y'] >= 0.45 / @scale) {
			@deg = _position_degrees(@position, entity_loc(@id)['yaw']);
			if(@deg > 0) {
				@poseable = 'LegRight';
			} else {
				@poseable = 'LegLeft';
			}
		}
		return(@poseable);
	}

	@item = pinv(player(), null);
	@armorstand = entity_spec(@event['id']);
	if(is_null(@item) && pinfo(player(), 11)) {
		if(!@armorstand['visible']) {
			die();
		}

		@posing = import(player().'posing');
		if(@posing) {
			die();
		}

		export(player().'posing', true);
		cancel();

		@poseable = _get_poseable(@event['id'], @armorstand, @event['position']);

		# Start posing
		if(@poseable === 'armorstand') {
			title_msg(null, color(6).'Rotating Armor Stand.', 0, 40, 10);

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

		} else if(@poseable === 'Torso') {
			title_msg(null, color(6).'Adjusting Armor Stand position.', 0, 40, 10);

			@eloc = entity_loc(@event['id']);
			@originalYaw = @eloc['yaw'];
			@dist = _distance(@eloc, _relative(ploc(), 'up'));
			set_entity_spec(@event['id'], array('gravity': false));

			set_interval(50, closure(){
				if(!ponline(player()) || !pinfo(player(), 11) || !entity_exists(@event['id'])) {
					try {
						set_entity_spec(@event['id'], array('gravity': @armorstand['gravity']));
					} catch(BadEntityException @ex) {
						// no longer exists
					}
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
			title_msg(null, color(6).'Posing '.@poseable.'.', 0, 40, 10);

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
				if(@poseable === 'poseHead') {
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

	} else {
		switch(if(@item, @item['type'], null)) {
			case 280: # 2 sticks attaches arms
				if(@item['qty'] >= 2 && !@armorstand['arms']) {
					set_entity_spec(@event['id'], array('arms': true));
					@item['qty'] -= 2;
					set_pinv(player(), array(null: if(@item['qty'] > 0, @item, null)));
					cancel();
				}

			case 288: # feather toggles gravity
				if(!_is_survival_world(pworld())) {
					@gravity = if(@armorstand['gravity'], false, true);
					title_msg(null, color(6).'Toggled gravity '.if(@gravity, 'on', 'off').' for armor stand.', 0, 40, 10);
					set_entity_spec(@event['id'], array('gravity': @gravity));
					cancel();
				}

			case 375: # spider eye toggles visibility
				if(!_is_survival_world(pworld())) {
					@visible = if(@armorstand['visible'], false, true);
					title_msg(null, color(6).'Toggled visibility '.if(@visible, 'on', 'off').' for armor stand.', 0, 40, 10);
					set_entity_spec(@event['id'], array('visible': @visible));
					cancel();
				}

			case 416: # armor stand toggles size
				if(!_is_survival_world(pworld())) {
					@small = if(@armorstand['small'], false, true);
					title_msg(null, color(6).if(@small, 'Shrunk', 'Embiggened').' armor stand.', 0, 40, 10);
					set_entity_spec(@event['id'], array('small': @small));
					cancel();
				}

			case 420: # lead carries armor stand
				if(!pinfo(player(), 11) && !get_entity_rider(puuid())) {
					cancel();
					title_msg(null, color(6).'Moving Armor Stand. Click to place.', 0, 40, 10);
					bind(player_interact, null, array('player': player()), @event, @world = pworld(), @stand = @event['id']) {
						if(array_index_exists(@event, 'location')) {
							unbind();
							@loc = @event['location'];
							if(@loc['world'] != @world || !entity_exists(@stand)) {
								die();
							}
							@loc = _relative(@loc, @event['facing']);
							@loc['x'] += 0.5;
							@loc['z'] += 0.5;
							set_entity_loc(@stand, @loc);
						}
					}
				}

			default:
				@poseable = _get_poseable(@event['id'], @armorstand, @event['position']);
				if(@poseable == 'ArmLeft' || @poseable == 'Head') {
					@slot = 'off_hand';
					if(@poseable == 'Head') {
						@slot = 'helmet';
					}
					cancel();
					@tool = get_mob_equipment(@event['id'])[@slot];
					if(!@item) {
						if(@tool) {
							@equipment = associative_array();
							@equipment[@slot] = null;
							set_mob_equipment(@event['id'], @equipment);
							set_pinv(player(), array(null: @tool));
						}
					} else if(@item['qty'] == 1 || !@tool) {
						@oldQty = @item['qty'];
						@item['qty'] = 1;
						@equipment = associative_array();
						@equipment[@slot] = @item;
						set_mob_equipment(@event['id'], @equipment);
						if(!@tool) {
							if(@oldQty > 1) {
								@item['qty'] = @oldQty - 1;
								set_pinv(player(), array(null: @item));
							} else {
								set_pinv(player(), array(null: null));
							}
						} else {
							set_pinv(player(), array(null: @tool));
						}
					}
				}

		}
	}
}

bind(entity_damage, null, array('type': 'ARMOR_STAND'), @event) {
	@damager = '';
	if(array_index_exists(@event, 'shooter')) {
		@damager = @event['shooter'];
	} else if(array_index_exists(@event, 'damager')) {
		@damager = @event['damager'];
	}

	if(@damager === '') {
		die();
	}
	
	if(!ponline(@damager)) {
		if(@event['cause'] == 'ENTITY_EXPLOSION' && entity_type(@damager) == 'FIREWORK') {
			cancel();
		}
	} else if(sk_can_build(@damager, @event['location'])) {
		@armorstand = entity_spec(@event['id']);
		if(!@armorstand['visible']) {
			die();
		}
		if(@armorstand['arms']) {
			if(!array_index_exists(@event, 'shooter')) {
				cancel();
			}
			@equipment = get_mob_equipment(@event['id']);
			@loc = entity_loc(@event['id']);
			if(!is_null(@equipment['weapon'])) {
				drop_item(@loc, @equipment['weapon']);
				set_mob_equipment(@event['id'], array('weapon': null));
			}
			if(!is_null(@equipment['off_hand'])) {
				drop_item(@loc, @equipment['off_hand']);
				set_mob_equipment(@event['id'], array('off_hand': null));
			}
			drop_item(@loc, array('type': 280, 'qty': 2));
			set_entity_spec(@event['id'], array('arms': false));
		} else if(@armorstand['baseplate'] && !array_index_exists(@event, 'shooter')) {
			cancel();
			set_entity_spec(@event['id'], array('baseplate': false));
		}
	}
}
