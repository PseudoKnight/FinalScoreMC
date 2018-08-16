array_push(@pvp['binds'], @id.'grapple')
bind('projectile_launch', array('id': @id.'grapple'), array('type': 'FISHING_HOOK'), @event, @pvp) {
	@player = @event['player'];
	@hook = @event['id'];

	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	@arrow = shoot_projectile(@player, 'arrow');
	set_entity_spec(@arrow, array('critical': true));
	set_arrow_damage(@arrow, 0.5);
	play_sound(ploc(@player), array('sound': 'ENTITY_ARROW_SHOOT'));
	@shooter = puuid(@player);
	@slot = pheld_slot(@player);

	set_timeout(50, closure(){
		try(set_entity_rider(@arrow, @hook));
	});

	proc _reel(@loc2, @shooter, @slot, @hook, @target, @mover) {

		@player = player(@shooter);
		@loc1 = entity_loc(@shooter);
		@startingHealth = max(1, get_entity_health(@shooter));

		@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));
		if(@dist >= 32) {
			if(@target != @shooter) {
				try(entity_remove(@target));
			}
			die();
		}

		play_sound(@loc1, array('sound': 'ENTITY_IRON_GOLEM_HURT', 'pitch': 2));
		play_sound(@loc2, array('sound': 'ENTITY_IRON_GOLEM_HURT', 'pitch': 2));
		play_sound(@loc1, array('sound': 'ENTITY_HORSE_BREATHE', 'pitch': 1.7));

		@endtask = closure(){
			try {
				if(!entity_grounded(@mover) && !get_entity_gliding(@mover)
				&& entity_exists(@hook) && entity_loc(@mover)['y'] < entity_loc(@hook)['y'] - 0.35) {
					set_entity_velocity(@mover, array(0, 0.4, 0));
				}
			} catch(BadEntityException @ex) {
				// sometimes the mover dies
			}

			if(ponline(@player)) {
				set_pinv(@player, @slot, null);
				set_timeout(50, closure(){
					set_pinv(@player, @slot, array('name': 'FISHING_ROD'));
				});
			}
		}
		@task = closure(@interval = true){
			try {
				if(get_entity_health(@shooter) < @startingHealth - 0.5
				|| get_entity_health(@mover) == 0
				|| pheld_slot(@player) != @slot
				|| !entity_exists(@hook)) {
					play_sound(ploc(@shooter), array('sound': 'ENTITY_ARROW_HIT', 'pitch': 1.5));
					if(@interval) {
						clear_task();
					}
					execute(@endtask);
				} else {
					@loc2 = entity_loc(@target);
					@loc1 = entity_loc(@mover);
					@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));
					@dist = clamp(@dist, 0.1, 20);
					set_entity_fall_distance(@mover, 0);
					if(@dist > 2.5) {
						if(@dist > 10) {
							@pitch = 1.4 + (0.6 * (@dist - 10) / 20);
							play_sound(@loc1, array('sound': 'ENTITY_HORSE_BREATHE', 'pitch': @pitch));
						}
						if(get_entity_gliding(@mover)) {
							@dist = @dist / 1.8;
						}
						@x = (@loc2['x'] - @loc1['x']) / @dist;
						@y = (@loc2['y'] - @loc1['y']) / @dist * 1.078;
						@z = (@loc2['z'] - @loc1['z']) / @dist;
						set_entity_velocity(@mover, array(@x, @y, @z));
					} else if(!psneaking(@player)) {
						if(@interval) {
							clear_task();
						}
						execute(@endtask);
						if(entity_type(@target) == 'ARROW') {
							entity_remove(@target);
						}
					} else {
						set_entity_velocity(@mover, array(0, 0, 0));
						set_mob_effect(@mover, 25, -1, 0.15);
					}
				}
			} catch(BadEntityException @e) {
				if(@interval) {
					clear_task();
				}
				execute(@endtask);
			}
		}
		execute(false, @task);
		set_interval(100, @task);
	}

	bind('projectile_hit', array('id': 'hit'.@arrow), array('id': @arrow), @event, @shooter, @slot, @hook) {
		unbind();
		if(@event['hittype'] == 'ENTITY') {
			@hit = @event['hit'];
			try(set_entity_rider(@hit, @hook));
			_reel(@event['location'], @shooter, @slot, @hook, @shooter, @hit);
		} else {
			_reel(@event['location'], @shooter, @slot, @hook, @event['id'], @shooter);
		}
	}

	set_timeout(800, closure(){
		if(has_bind('hit'.@arrow)) {
			try(entity_remove(@arrow));
			unbind('hit'.@arrow);
		}
	});
}

array_push(@pvp['binds'], @id.'grappledamage');
bind('entity_damage', array('id': @id.'grappledamage'), array('type': 'PLAYER', 'cause': 'FLY_INTO_WALL'), @event, @pvp) {
	if(array_index_exists(@pvp['players'], @event['player'])) {
		cancel();
	}
}

array_push(@pvp['binds'], @id.'grapplepickup');
bind('item_pickup', array('id': @id.'grapplepickup'), array('item': 262), @event, @pvp) {
	if(array_index_exists(@pvp['players'], player()) && psneaking()) {
		cancel();
	}
}
