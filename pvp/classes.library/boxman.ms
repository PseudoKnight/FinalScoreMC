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

	bind(player_interact, array('id': @player.'boxmanattack'), array('player': @player), @e, @pvp) {
		@slot = 0;
		@checkSlot = -106;
		if(@e['button'] == 'left') {
			@slot = -106;
			@checkSlot = 0;
		}
		@item = pinv(player(), @slot);
		if(@item && @item['name'] == 'STEP') {
			@loc = _relative(ploc(), 'up');

			@targetLoc = pcursor(array(0, 65, 66, 68, 70, 72, 77, 85, 143, 147, 148, 157, 171, 188, 189, 190, 191, 192));
			psend_block_change(player(), @targetLoc, '35:2');
			set_timeout(800, closure(){
				psend_block_change(player(), @targetLoc, get_block_at(@targetLoc));
			});
			@target = '';
			foreach(@p in players_in_radius(@targetLoc, 4)){
				if(@p != player() && raw_pcan_see(@p)) {
					@target = puuid(@p);
				}
			}
			if(!@target) {
				die();
			}

			@inv = associative_array();
			@inv[@slot] = null;
			set_pinv(player(), @inv);

			if(!pinv(player(), @checkSlot)) {
				set_pwalkspeed(player(), 0.1);
			}

			@loc = _relative(ploc(), 'up');
			@box = spawn_entity('ARMOR_STAND', 1, @loc)[0];
			set_mob_equipment(@box, array('WEAPON': @item));
			set_entity_spec(@box, array(
				'gravity': false,
				'visible': false,
				'arms': true,
				'poses': array(
					'poseArmRight': array(
						'x': 0.8,
						'y': 0.6,
						'z': -0.8,
					),
				),
			));

			@returnToSender = closure(){
				if(ponline(player()) && phealth() > 0 && array_index_exists(@pvp['players'], player())) {
					set_pwalkspeed(player(), 0.2);
					@inv[@slot] = array('name': 'CONCRETE', 'data': 2);
					set_pinv(player(), @inv);
					set_timeout(1200, closure(){
						if(ponline(player()) && phealth() > 0 && array_index_exists(@pvp['players'], player())) {
							@inv[@slot] = @item;
							set_pinv(player(), @inv);
						}
					});
				}
				try {
					entity_remove(@box);
				} catch(BadEntityException @ex) {
					// Destroyed.
				}
			}

			set_interval(50, closure(){
				try {
					if(get_entity_health(@target) <= 0
					|| !ponline(player())
					|| phealth() == 0
					|| !array_index_exists(@pvp['players'], player())) {
						clear_task();
						execute(@returnToSender);
					} else {
						@loc = entity_loc(@box);
						@targetLoc = entity_loc(@target);
						set_entity_loc(@box, location_shift(@loc, @targetLoc, 0.3));
						if(_distance(@loc, @targetLoc) < 1) {
							damage_entity(@target, 1, puuid());
						}
						play_named_sound(@loc, array('sound': 'entity.guardian.attack'));
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
				play_named_sound(@loc, array('sound': 'block.enderchest.open'));
				entity_remove(@e['id']);
				consume();
			}
		}
	}
	
	@sneakLoc = array();
	bind(player_toggle_sneak, associative_array('id': @player.'sneak'), array('player': @player), @event, @pvp, @sneakLoc) {
		if(@event['sneaking']) {
			@sneakLoc['x'] = @event['location']['x'];
			@sneakLoc['y'] = @event['location']['y'];
			@sneakLoc['z'] = @event['location']['z'];
			@sneakLoc['world'] = @event['location']['world'];
			set_pinv(player(), array(103: null));
			@block = get_block_at(ploc());
			foreach(@p: @player in @pvp['players']) {
				if(@p != player()) {
					psend_block_change(@p, @sneakLoc, @block);
				}
			}
		} else {
			set_pinv(player(), array(103: array('name': 'STEP', 'data': 8)));
			@block = get_block_at(@sneakLoc);
			foreach(@p: @player in @pvp['players']) {
				if(@p != player()) {
					psend_block_change(@p, @sneakLoc, @block);
				}
			}
		}
	}

case 'unload':
	unbind(@player.'boxman');
	unbind(@player.'boxmanclick');
	unbind(@player.'boxmanattack');
	unbind(@player.'boxmanbox');
	unbind(@player.'sneak');
	set_pwalkspeed(player(), 0.2);

}
