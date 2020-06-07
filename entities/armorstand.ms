foreach(@p in all_players()) {
	export(@p.'posing', null);
}

bind('player_interact_at_entity', null, array('clicked': 'ARMOR_STAND'), @event) {
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
	if(is_null(@item) && psneaking()) {
		if(!@armorstand['visible']) {
			cancel();
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
			title('', color(6).'Rotating Armor Stand.', 0, 40, 10);

			@dir = pfacing();
			@eloc = entity_loc(@event['id']);
			@newloc = @eloc[];

			@taskid = set_interval(50, closure(){
				if(!psneaking() || !entity_exists(@event['id'])) {
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
			title('', color(6).'Adjusting Armor Stand position.', 0, 40, 10);

			@eloc = entity_loc(@event['id']);
			@originalYaw = @eloc['yaw'];
			@dist = distance(@eloc, location_shift(ploc(), 'up'));
			set_entity_spec(@event['id'], array('gravity': false));

			set_interval(50, closure(){
				if(!ponline(player()) || !psneaking() || !entity_exists(@event['id'])) {
					try {
						if(pmode() == 'CREATIVE') {
							set_entity_spec(@event['id'], array('gravity': @armorstand['gravity']));
						} else {
							set_entity_spec(@event['id'], array('gravity': !get_block_info(entity_loc(@event['id']), 'solid')));
						}
					} catch(BadEntityException @ex) {
						// no longer exists
					}
					clear_task();
					export(player().'posing', null);
					return();
				}

				@eloc = location_shift(ploc(), 'up', 1.3);
				@yaw = to_radians(@eloc['yaw'] + 90);
				@pitch = to_radians(0 - @eloc['pitch']);
				@eloc['x'] += @dist * cos(@yaw) * cos(@pitch);
				@eloc['y'] += @dist * sin(@pitch);
				@eloc['z'] += @dist * sin(@yaw) * cos(@pitch);
				@eloc['yaw'] = @originalYaw;
				set_entity_loc(@event['id'], @eloc);
			});

		} else {
			title('', color(6).'Posing '.@poseable.'.', 0, 40, 10);

			@dir = pfacing();
			@eloc = entity_loc(@event['id']);
			@dist = distance(@eloc, ploc());
			@poseable = 'pose'.@poseable;
			@newspec = associative_array('poses': array());
			@newspec['poses'][@poseable] = @armorstand['poses'][@poseable][];

			set_interval(50, closure(){
				if(!ponline(player()) || !psneaking() || !entity_exists(@event['id'])) {
					clear_task();
					export(player().'posing', null);
					return();
				}

				@newdir = pfacing();
				@newdist = distance(@eloc, ploc());

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
		switch(if(@item, @item['name'], null)) {
			case 'STICK': # 2 sticks attaches arms
				if(@item['qty'] >= 2 && !@armorstand['arms']) {
					set_entity_spec(@event['id'], array('arms': true));
					@item['qty'] -= 2;
					set_pinv(player(), null, @item);
					cancel();
				}

			case 'FEATHER': # toggles gravity
				if(!_is_survival_world(pworld())) {
					@gravity = if(@armorstand['gravity'], false, true);
					title('', color(6).'Toggled gravity '.if(@gravity, 'on', 'off').' for armor stand.', 0, 40, 10);
					set_entity_spec(@event['id'], array('gravity': @gravity));
					cancel();
				}

			case 'SPIDER_EYE': # toggles visibility
				if(!_is_survival_world(pworld())) {
					@gear = get_mob_equipment(@event['id'])
					@visible = @armorstand['visible'];
					if(!@visible || @gear['weapon'] || @gear['off_hand'] || @gear['helmet'] || @gear['chestplate'] || @gear['leggings'] || @gear['boots']) {
						title('', color(6).'Toggled visibility '.if(@visible, 'off', 'on').' for armor stand.', 0, 40, 10);
						set_entity_spec(@event['id'], array('visible': !@visible));
						cancel();
					}
				}

			case 'ARMOR_STAND': # toggles size
				if(!_is_survival_world(pworld())) {
					@small = if(@armorstand['small'], false, true);
					title('', color(6).if(@small, 'Shrunk', 'Embiggened').' armor stand.', 0, 40, 10);
					set_entity_spec(@event['id'], array('small': @small));
					cancel();
				}

			case 'NAME_TAG': # adds mob name
				if(!_is_survival_world(pworld())) {
					if(!@item['meta'] || !@item['meta']['display']) {
						set_mob_name(@event['id'], '');
						set_name_visible(@event['id'], false);
					} else {
						set_mob_name(@event['id'], @item['meta']['display']);
						set_name_visible(@event['id'], true);
					}
					cancel();
				}

			case 'LEAD': # carries armor stand
				if(!psneaking() && !get_entity_rider(puuid())) {
					cancel();
					title('', color(6).'Moving Armor Stand. Click to place.', 0, 40, 10);
					bind('player_interact', null, array('player': player()), @event, @world = pworld(), @stand = @event['id']) {
						if(array_index_exists(@event, 'location')) {
							unbind();
							@loc = @event['location'];
							if(@loc['world'] != @world || !entity_exists(@stand)) {
								die();
							}
							@loc = location_shift(@loc, @event['facing']);
							@loc['x'] += 0.5;
							@loc['z'] += 0.5;
							set_entity_loc(@stand, @loc);
						}
					}
				}

			default:
				@equipment = get_mob_equipment(@event['id']);
				if(!@armorstand['visible']) {
					cancel();
					die();
				}
				@poseable = _get_poseable(@event['id'], @armorstand, @event['position']);
				if(@poseable == 'ArmLeft' || @poseable == 'Head') {
					@slot = 'off_hand';
					if(@poseable == 'Head') {
						@slot = 'helmet';
					}
					cancel();
					@tool = @equipment[@slot];
					if(!@item) {
						if(@tool) {
							@equipment = associative_array();
							@equipment[@slot] = null;
							set_mob_equipment(@event['id'], @equipment);
							set_pinv(player(), null, @tool);
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
								set_pinv(player(), null, @item);
							} else {
								set_pinv(player(), null, null);
							}
						} else {
							set_pinv(player(), null, @tool);
						}
					}
				}

		}
	}
}

bind('player_interact', null, array('itemname': 'ARMOR_STAND', 'button': 'right'), @event) {
	if(@event['action'] == 'right_click_block') {
		title('', color(6).'Use an open hand whilst sneaking to pose');
	}
}

bind('entity_damage', null, array('type': 'ARMOR_STAND'), @event) {
	@damager = '';
	if(array_index_exists(@event, 'shooter')) {
		@damager = @event['shooter'];
	} else if(array_index_exists(@event, 'damager')) {
		@damager = @event['damager'];
	}

	if(@damager && ponline(@damager) && sk_can_build(@damager, @event['location'])) {
		@armorstand = entity_spec(@event['id']);
		if(!@armorstand['visible']) {
			die();
		}
		@trace = ray_trace(@damager, 4);
		@loc = null;
		try {
			@loc = @trace['entities'][0]['location'];
		} catch (IndexOverflowException @ex) {
			die();
		}
		@loc['y'] -= @event['location']['y'];
		@scale = if(@armorstand['small'], 2, 1);
		@poseable = 'Feet';
		if(@loc['y'] >= 1.6 / @scale) {
			@poseable = 'Head';
		} else if(@loc['y'] >= 0.9 / @scale) {
			@poseable = 'Torso';
		} else if(@loc['y'] >= 0.45 / @scale) {
			@poseable = 'Legs';
		}

		if(@poseable == 'Torso' && @armorstand['arms']) {
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
			drop_item(@loc, array('name': 'STICK', 'qty': 2));
			set_entity_spec(@event['id'], array('arms': false));
		} else if(@poseable == 'Feet' && @armorstand['baseplate'] && !array_index_exists(@event, 'shooter')) {
			cancel();
			set_entity_spec(@event['id'], array('baseplate': false));
		}
	}
}
