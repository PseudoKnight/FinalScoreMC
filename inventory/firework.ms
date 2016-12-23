bind(player_interact, null, array('item': 401, 'button': 'right'), @event) {
	if(get_entity_gliding(puuid())) {
        set_timeout(100, closure(){
            set_entity_gliding(puuid(), true);
        });
        
    } else if(!_is_survival_world(pworld())) {
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
    		if(@f > 1 && !rand(5)) {
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
		foreach(@m in @mobs){
			if(@mob == 'pig'){
				set_mob_equipment(@m, associative_array('CHESTPLATE': associative_array('name': 'ELYTRA')));
				set_equipment_droprates(@m, null);
				set_entity_gliding(@m, true);
			}
			set_entity_onfire(@m, 20);
			set_mob_effect(@m, 20, 0, 600, true, false);
			set_entity_velocity(@m, _get_vector(@yaw, 0));
			@yaw += 24;
		}
	}
}
