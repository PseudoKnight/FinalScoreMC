bind('player_interact', null, array('itemname': 'FIREWORK_ROCKET', 'button': 'right'), @event) {
	if(@event['hand'] == 'off_hand' && @event['block'] == 'IRON_DOOR') {
		// ignore iron doors if we are not boosting; Deadbolt already cancels main hand
		cancel();
		die();
	}
	@uuid = puuid();
	@gliding = false;
	@grounded = true;
	try {
		@gliding = get_entity_gliding(@uuid);
		@grounded = entity_grounded(@uuid);
	} catch(BadEntityException @ex) {}
	@world = pworld();
	if(@gliding || !@grounded && (@chestplate = pinv(player(), 102)) && @chestplate['name'] == 'ELYTRA') {
		if(!@gliding) {
			set_entity_gliding(@uuid, true);
			@gliding = true;
		}
		set_timeout(150, closure(){
			try(set_entity_gliding(@uuid, true))
		});
	}
	@slot = if(@event['hand'] == 'main_hand', null, -106);
	@item = pinv(player(), @slot);
	@lore = _item_meta(@item, 'lore');
	if(@lore) {
		@mobs = array();
		foreach(@line in @lore) {
			@split = split(': ', @line, 1);
			if(array_size(@split) == 2 && @split[0] == color('gray').'Spawn Type') {
				@mobs[] = @split[1];
			}
		}
		if(@mobs) {
			if(@gliding) {
				@loc = location_shift(ploc(), 'up');
				@vehicle = null;
				foreach(@mob in @mobs) {
					@rider = spawn_entity(@mob, 1, @loc)[0];
					if(@vehicle) {
						set_entity_rider(@vehicle, @rider);
					}
					@vehicle = @rider;
				}
			} else {
				cancel(); // handle manually
				@loc = location_shift(ploc(), 'up', 2);
				if(@event['block']) {
					@loc = location_shift(@event['location'], @event['facing']);
					@loc['x'] += 0.5;
					@loc['y'] += 0.5;
					@loc['z'] += 0.5;
				}
				@vehicle = launch_firework(@loc, @item['meta']['firework']);
				if(!@event['block']) {
					set_entity_velocity(@vehicle, get_vector(ploc(), 0.05));
				}
				foreach(@mob in @mobs) {
					@rider = spawn_entity(@mob, 1, @loc)[0];
					if(!_is_survival_world(@loc['world'])) {
						set_mob_effect(@rider, 'WITHER', 4, 999, true, false);
					}
					set_mob_effect(@rider, 'RESISTANCE', 4, 10, true, false);
					set_entity_rider(@vehicle, @rider);
					@vehicle = @rider;
				}
				if(pmode() != 'CREATIVE') {
					@item['qty']--;
					set_pinv(player(), @slot, @item);
				}
			}
			die();
		}

	}
	if(!@gliding && (@world == 'custom' || @world == 'dev')) {
		@pdata = _pdata(player());
		if(!array_index_exists(@pdata, 'support')) {
			die();
		}

		@slot = -106;
		if(@event['hand'] == 'main_hand') {
			@slot = pheld_slot();
		}
		@item = pinv(player(), @slot);
		if(@item['meta'] && @item['meta']['firework']['effects']) {
			die();
		}

		cancel();
		@loc = null;
		if(@event['action'] === 'right_click_block') {
			@loc = location_shift(@event['location'], @event['facing']);
			@ploc = ploc();
			@loc['yaw'] = @ploc['yaw'];
			@loc['pitch'] = @ploc['pitch'];
		} else {
			@loc = location_shift(ploc(), 'up');
		}
		@loc['x'] += 0.5;
		@loc['z'] += 0.5;

		@colors = array();
		for(@i = 0, @i < 3, @i++) {
			@colors[] = array(rand(256), rand(256), rand(256));
		}

		foreach(@f in range(rand(2, 4))) {
			@meta = associative_array('strength': @f, 'effects': array());
			@num = rand(1, 3);
			foreach(@m in range(@num)) {
				@type = array_get_rand(array('BALL', 'BALL_LARGE', 'STAR', 'BURST', 'CREEPER'));
				@startcolors = array_rand(@colors, rand(1, 3), false);
				@endcolors = array_filter(@colors, closure(@key, @value){
					return(!array_contains(@startcolors, @value));
				});
				@meta['effects'][] = associative_array(
					'flicker': rand(2),
					'colors': @startcolors,
					'fade': @endcolors,
					'type': @type,
				);
			}
			@firework = launch_firework(@loc, @meta);
			if(@f > 1 && !rand(4)) {
				set_metadata(@firework, 'mob', array_get_rand(array('chicken', 'bat', 'pig')));
			}
			if(pworld() == 'dev' && @f == 2) {
				set_metadata(@firework, 'spec', player());
				set_metadata(@firework, 'loc', ploc());
				@stand = spawn_entity('ARMOR_STAND', 1, @loc, closure(@e){
					set_entity_spec(@e, array(visible: false, gravity: false));
				})[0];
				set_entity_rider(@firework, @stand);
				set_pmode(player(), 'SPECTATOR');
				set_pspectator_target(player(), @stand);
				unbind(player().'firework');
				bind('player_toggle_sneak', array(id: player().'firework'), array(player: player()), @event) {
					cancel();
				}
			}
		}

		@item['name'] = 'FIREWORK_STAR';
		set_pinv(player(), @slot, @item);
		set_timeout(4000, closure(){
			try {
				if(pworld() == @world) {
					@item = pinv(player(), @slot);
					if(@item && @item['name'] == 'FIREWORK_STAR') {
						@item['name'] = 'FIREWORK_ROCKET';
						set_pinv(player(), @slot, @item);
					}
				}
			} catch(PlayerOfflineException @ex) {
				// ignore
			}
		});
	}
}

bind('projectile_launch', null, array(shootertype: 'PLAYER', type: 'FIREWORK'), @event) {
	@item = pinv(player(), null);
	if(!@item || @item['name'] != 'CROSSBOW') {
		@item = pinv(player(), -106);
		if(!@item || @item['name'] != 'CROSSBOW') {
			die();
		}
	}
	try {
		@projectileMeta = @item['meta']['projectiles'][0]['meta'];
		if(@projectileMeta && @projectileMeta['lore'] && pcooldown('CROSSBOW') == 0) {
			set_pcooldown('CROSSBOW', 1);
			@mobs = array();
			foreach(@line in @projectileMeta['lore']) {
				@split = split(': ', @line, 1);
				if(array_size(@split) == 2 && @split[0] == color('gray').'Spawn Type') {
					@mobs[] = @split[1];
				}
			}
			if(@mobs) {
				@vehicle = @event['id'];
				set_timeout(10, closure(){
					@loc = entity_loc(@event['id']);
					foreach(@mob in @mobs) {
						@rider = spawn_entity(@mob, 1, @loc)[0];
						if(!_is_survival_world(@loc['world'])) {
							set_mob_effect(@rider, 'WITHER', 4, 999, true, false);
						}
						set_entity_rider(@vehicle, @rider);
						set_mob_effect(@rider, 'RESISTANCE', 4, 10, true, false);
						@vehicle = @rider;
					}
					set_entity_rider(@vehicle, @event['id']);
				});
			}
		}

	} catch(IndexOverflowException @ignore) {}
}

bind('firework_explode', null, null, @event){
	if(!entity_exists(@event['id'])) {
		// rare cases this will happen
		die();
	}
	if(has_metadata(@event['id'], 'spec')) {
		@player = get_metadata(@event['id'], 'spec', 'CommandHelper');
		@returnLoc = get_metadata(@event['id'], 'loc', 'CommandHelper');
		@stand = get_entity_rider(@event['id']);
		set_timeout(1500, closure(){
			try(entity_remove(@stand))
			unbind(@player.'firework');
			if(ponline(@player) && pmode(@player) == 'SPECTATOR') {
				set_ploc(@player, @returnLoc);
				set_pmode(@player, 'ADVENTURE');
			}
		});
	}
	if(has_metadata(@event['id'], 'mob')){
		@mob = get_metadata(@event['id'], 'mob', 'CommandHelper');
		@loc = @event['location'];
		@loc['yaw'] = 0;
		@loc['pitch'] = 0;
		@cookie = @mob == 'bat' && rand(2);
		set_timeout(0, closure(){
			@mobs = spawn_entity(@mob, 15, @event['location'], closure(@m) {
				set_entity_onfire(@m, 20);
				if(@mob == 'pig'){
					set_mob_equipment(@m, associative_array('CHESTPLATE': associative_array('name': 'ELYTRA')));
					set_equipment_droprates(@m, null);
					set_entity_gliding(@m, true);
				} else if(@cookie) {
					@item = spawn_entity('DROPPED_ITEM', 1, @loc)[0];
					set_entity_rider(@m, @item);
					set_entity_onfire(@m, 0);
					set_entity_spec(@item, array('itemstack': array('name': 'COOKIE')));
				}
				set_entity_velocity(@m, get_vector(@loc));
				@loc['yaw'] += 24;
			});
			try {
				foreach(@m in @mobs){
					if(@cookie) {
						set_mob_effect(@m, 'invisibility', 0, 600, true, false);
					}
					set_mob_effect(@m, 'wither', 0, 600, true, false);
				}
			} catch(BadEntityException @ex) {
				// firework may have exploded right before chunk unloaded
			}
		});
	} else if(!has_metadata(@event['id'], 'extended')) {
		@v = entity_velocity(@event['id']);
		if(@v['y'] < 0.45 && @v['magnitude'] < 0.7) {
			// velocity characteristic of a horizontal dispenser, but not player
			cancel();
			set_metadata(@event['id'], 'extended', true);
			set_entity_spec(@event['id'], array('strength': entity_spec(@event['id'])['strength'] * 3));
		}
	}
}