switch(@action) {
case 'load':
	set_pheld_slot(@player, 0);
	bind(item_held, array('id': @player.'boxman'), null, @e, @p = @player) {
		if(@e['player'] == @p) {
			cancel();
		}
	}

	bind(inventory_click, array('id': @player.'boxmanclick'), array('player': @player), @e) {
		cancel();
	}

	bind(player_interact, array('id': @player.'boxmanattack'), array('player': @player), @e) {
		@slot = if(@e['button'] == 'left', -106, 0);
		@item = pinv(player(), @slot);
		if(@item) {
			proc _box_target(@loc) {
				@players = players_in_radius(@loc, 16);
				foreach(@p in @players){
					if(@p != player() && raw_pcan_see(@p)) {
						return(puuid(@p));
					}
				}
			}

			@loc = _relative(ploc(), 'up');

			@target = _box_target(ptarget_space());
			if(!@target) {
				_box_target(@loc);
				if(!@target) {
					die();
				}
			}

			@inv = associative_array();
			@inv[@slot] = null;
			set_pinv(player(), @inv);

			@loc = _relative(ploc(), 'up');
			@box = spawn_entity('ARMOR_STAND', 1, @loc)[0];
			set_mob_equipment(@box, associative_array('WEAPON': @item));
			set_entity_spec(@box, associative_array(
				'gravity': false,
				'visible': false,
				'arms': true,
				'poses': associative_array(
					'poseArmRight': associative_array(
						'x': 0.8,
						'y': 0.6,
						'z': -0.8,
					),
				),
			));

			@returnToSender = closure(){
				if(ponline(player()) && pinfo(player(), 5) > 0) {
					@helmet = pinv(player(), 103);
					if(@helmet && @helmet['type'] == 44) {
						@inv[@slot] = @item;
						set_pinv(player(), @inv);
					}
				}
				try {
					entity_remove(@box);
				} catch(BadEntityException @ex) {
					// Destroyed.
				}
			}

			set_interval(150, closure(){
				try {
					if(get_entity_health(@target) <= 0 || !ponline(player()) || pinfo(player(), 5) == 0
					|| !pinv(player(), 103)) {
						clear_task();
						execute(@returnToSender);
					} else {
						@loc = entity_loc(@box);
						@targetLoc = entity_loc(@target);
						set_entity_loc(@box, location_shift(@loc, @targetLoc, 1));
						if(_distance(@loc, @targetLoc) < 1.1) {
							damage_entity(@target, 2, puuid());
						}
						play_named_sound(@loc, associative_array('sound': 'entity.guardian.attack'));
					}
				} catch(Exception @ex) {
					clear_task();
					execute(@returnToSender);
				}
			});
		}
	}

	bind(entity_damage, array('id': @player.'boxmanbox', 'priority': 'HIGH'), array('type': 'ARMOR_STAND'), @e, @pvp) {
		if((array_index_exists(@e, 'damager') && array_index_exists(@pvp['players'], @e['damager']))
		|| (array_index_exists(@e, 'shooter') && array_index_exists(@pvp['players'], @e['shooter']))) {
			@weapon = get_mob_equipment(@e['id'])['weapon']
			if(@weapon && @weapon['type'] == 44) {
				@loc = entity_loc(@e['id']);
				play_effect(@loc, 'EXPLOSION_LARGE');
				play_named_sound(@loc, associative_array('sound': 'block.enderchest.open'));
				entity_remove(@e['id']);
				consume();
			}
		}
	}

case 'unload':
	unbind(@player.'boxman');
	unbind(@player.'boxmanclick');
	unbind(@player.'boxmanattack');
	unbind(@player.'boxmanbox');

}
