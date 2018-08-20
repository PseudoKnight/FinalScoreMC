switch(@action) {
case 'load':
	set_pheld_slot(@player, 0);
	bind('item_held', array('id': @player.'boxman'), null, @e, @player) {
		if(@e['player'] == @player) {
			cancel();
		}
	}

	bind('inventory_click', array('id': @player.'boxmanclick'), array('player': @player), @e) {
		cancel();
	}

	bind('player_interact', array('id': @player.'boxmanattack'), array('player': @player), @e, @pvp) {
		@slot = 0;
		@checkSlot = -106;
		if(@e['button'] == 'left') {
			@slot = -106;
			@checkSlot = 0;
		}
		@item = pinv(player(), @slot);
		if(@item && @item['name'] == 'STEP') {
			@loc = location_shift(ploc(), 'up');

			@targetLoc = pcursor();
			psend_block_change(player(), @targetLoc, 'MAGENTA_WOOL');
			set_timeout(800, closure(){
				psend_block_change(player(), @targetLoc, get_block(@targetLoc));
			});
			@target = '';
			foreach(@p in players_in_radius(@targetLoc, 4)){
				if(@p != player() && pmode(@p) != 'SPECTATOR') {
					@target = puuid(@p);
				}
			}
			if(!@target) {
				die();
			}

			set_pinv(player(), @slot, null);

			if(!pinv(player(), @checkSlot)) {
				set_pwalkspeed(player(), 0.1);
			}

			@loc = location_shift(ploc(), 'up');
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
				if(ponline(player()) && pmode() != 'SPECTATOR' && array_index_exists(@pvp['players'], player())) {
					set_pwalkspeed(player(), 0.2);
					set_pinv(player(), @slot, array('name': 'MAGENTA_CONCRETE'));
					set_timeout(1200, closure(){
						if(ponline(player()) && pmode() != 'SPECTATOR' && array_index_exists(@pvp['players'], player())) {
							set_pinv(player(), @slot, @item);
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
					|| pmode() == 'SPECTATOR'
					|| !array_index_exists(@pvp['players'], player())) {
						clear_task();
						execute(@returnToSender);
					} else {
						@loc = entity_loc(@box);
						@targetLoc = entity_loc(@target);
						set_entity_loc(@box, location_shift(@loc, @targetLoc, 0.3));
						if(distance(@loc, @targetLoc) < 1) {
							damage_entity(@target, 1, puuid());
						}
						play_sound(@loc, array('sound': 'ENTITY_GUARDIAN_ATTACK'));
					}
				} catch(Exception @ex) {
					clear_task();
					execute(@returnToSender);
				}
			});
		}
	}

	bind('entity_damage', array('id': @player.'boxmanbox', 'priority': 'HIGH'), array('type': 'ARMOR_STAND'), @e, @pvp, @player) {
		@damager = null;
		if(array_index_exists(@e, 'damager') && array_index_exists(@pvp['players'], @e['damager'])) {
			@damager = @e['damager'];
		} else if(array_index_exists(@e, 'shooter') && array_index_exists(@pvp['players'], @e['shooter'])) {
			@damager = @e['shooter'];
		}
		if(@damager && @damager != @player) {
			@weapon = get_mob_equipment(@e['id'])['weapon']
			if(@weapon && @weapon['name'] == 'STEP') {
				@loc = entity_loc(@e['id']);
				spawn_particlet(@loc, 'EXPLOSION_LARGE');
				play_sound(@loc, array('sound': 'BLOCK_ENDER_CHEST_OPEN'));
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
	set_pwalkspeed(player(), 0.2);

}
