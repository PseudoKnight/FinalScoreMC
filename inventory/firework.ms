bind(player_interact, null, array('item': 401, 'button': 'right'), @event) {
	@gliding = get_entity_gliding(puuid());
	if(@gliding) {
        set_timeout(150, closure(){
            set_entity_gliding(puuid(), true);
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
				@loc = _relative(ploc(), 'up');
				@horse = null;
				foreach(@mob in @mobs) {
					@rider = spawn_entity(@mob, 1, @loc)[0];
					if(@horse) {
						set_entity_rider(@horse, @rider);
					}
					@horse = @rider;
				}
			} else {
				cancel(); // handle manually
				if(@event['block'] != '0') {
					@loc = _relative(@event['location'], @event['facing']);
					@loc['x'] += 0.5;
					@loc['y'] += 0.5;
					@loc['z'] += 0.5;
					@horse = launch_firework(@loc, @item['meta']['firework']);
					set_entity_velocity(@horse, _get_vector(pfacing(), 0.05, 0));
					foreach(@mob in @mobs) {
						@rider = spawn_entity(@mob, 1, @loc)[0];
						set_entity_rider(@horse, @rider);
						@horse = @rider;
					}
				} else {
					@loc = _relative(ploc(), 'up', 2);
					@firework = launch_firework(@loc, @item['meta']['firework']);
					@horse = null;
					foreach(@mob in @mobs) {
						@rider = spawn_entity(@mob, 1, @loc)[0];
						if(@horse) {
							set_entity_rider(@horse, @rider);
						} else {
							set_mob_equipment(@rider, array('chestplate': array('name': 'ELYTRA')));
							set_equipment_droprates(@rider, null);
							set_entity_velocity(@rider, _get_vector(pfacing(), 1.5, 0));
							set_entity_gliding(@rider, true);
						}
						@horse = @rider;
					}
					set_entity_rider(@horse, @firework);
				}
				if(pmode() != 'CREATIVE') {
					@inv = associative_array();
					if(@item['qty'] > 1) {
						@item['qty']--;
						@inv[@slot] = @item;
					} else {
						@inv[@slot] = null;
					}
					set_pinv(@inv);
				}
			}
			die();
		}
		
	}
	if(!@gliding && (pworld() == 'custom' || pworld() == 'dev')) {
    	@pdata = _pdata(player());
    	if(!array_index_exists(@pdata, 'support')) {
    		die();
    	}
        
        @slot = -106;
        if(@event['hand'] == 'main_hand') {
            @slot = pinfo(player(), 15);
        }
        @item = pinv(player(), @slot);
        if(@item['meta'] && @item['meta']['firework']['effects']) {
            die();
        }
        
    	cancel();
    	if(@event['action'] === 'right_click_block') {
    		@loc = _relative(@event['location'], @event['facing']);
    	} else {
    		@loc = ploc();
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
    			@type = array_rand(array('BALL', 'BALL_LARGE', 'STAR', 'BURST', 'CREEPER'), 1, false)[0];
    			@startcolors = array_rand(@colors, rand(1, 3), false);
    			@endcolors = array_filter(@colors, closure(@key, @value){
    				return(!array_contains(@startcolors, @value));
    			});
    			@meta['effects'][] = associative_array(
    				'flicker': rand(2),
    				'trail': if(@num == 1, rand(2), 0),
    				'colors': @startcolors,
    				'fade': @endcolors,
    				'type': @type,
    			);
    		}
    		@firework = launch_firework(@loc, @meta);
    		if(@f > 1 && !rand(4)) {
    			set_metadata(@firework, 'mob', array_rand(array('chicken', 'bat', 'pig'), 1, false)[0]);
    		}
    	}

    	@item['type'] = 402;
    	@item['name'] = 'FIREWORK_CHARGE';
        @inv = associative_array();
        @inv[@slot] = @item;
    	set_pinv(player(), @inv);
    	set_timeout(4000, closure(){
    		try {
    			@item = pinv(player(), @slot);
    			if(@item && @item['type'] == 402) {
    				@item['type'] = 401;
    				@item['name'] = 'FIREWORK';
    				@inv = associative_array();
    				@inv[@slot] = @item;
    				set_pinv(player(), @inv);
    			}
    		} catch(PlayerOfflineException @ex) {
    			// ignore
    		}
    	});
    }
}

bind(firework_explode, null, null, @event){
	if(has_metadata(@event['id'], 'mob')){
		@mob = get_metadata(@event['id'], 'mob', 'CommandHelper');
		@mobs = spawn_mob(@mob, 15, @event['location']);
		@yaw = 0;
		@cookie = @mob == 'bat' && rand(2);
		foreach(@m in @mobs){
			set_entity_onfire(@m, 20);
			if(@mob == 'pig'){
				set_mob_equipment(@m, associative_array('CHESTPLATE': associative_array('name': 'ELYTRA')));
				set_equipment_droprates(@m, null);
				set_entity_gliding(@m, true);
			} else if(@cookie) {
				@cookie = spawn_entity('DROPPED_ITEM', 1, @event['location'])[0];
				set_entity_spec(@cookie, array('itemstack': array('name': 'COOKIE')));
				set_entity_rider(@m, @cookie);
				set_entity_onfire(@m, 0);
			}
			set_entity_velocity(@m, _get_vector(@yaw, 0));
			@yaw += 24;
		}
		set_timeout(50, closure(){
			try {
				foreach(@m in @mobs){
					if(@cookie) {
						set_mob_effect(@m, 14, 0, 600, true, false);
					}
					set_mob_effect(@m, 20, 0, 600, true, false);
				}
			} catch(BadEntityException @ex) {
				// firework may have exploded right before chunk unloaded
			}
		});
	}
}
