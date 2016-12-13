array_push(@pvp['binds'], @id.'grapple')
bind(projectile_launch, array('id': @id.'grapple'), array('type': 'FISHING_HOOK'), @event, @id) {
	@pvp = import('pvp'.@id);
	@player = @event['player'];
	@hook = @event['id'];

	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	if(!ptake_item(@player, 262, 1)) {
		die();
	}

	@arrow = shoot_projectile(@player, 'arrow');
	set_entity_spec(@arrow, array('critical': true));
	set_arrow_damage(@arrow, 1);
	play_sound(ploc(@player), array('sound': 'SHOOT_ARROW'));
	@shooter = puuid(@player);
	@slot = pinfo(@player, 15);

	set_timeout(50, closure(){
		try(set_entity_rider(@arrow, @hook));
	});

	proc _reel(@loc2, @shooter, @slot, @hook, @target, @mover) {

		@player = get_player_from_entity_id(@shooter);
		@loc1 = entity_loc(@shooter);
		@startingHealth = max(1, get_entity_health(@shooter));

		@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));
		if(@dist > 31) {
			if(@target != @shooter) {
				try(entity_remove(@target));
			}
			die();
		}

		play_sound(@loc1, array('sound': 'IRONGOLEM_HIT', 'pitch': 2));
		play_sound(@loc2, array('sound': 'IRONGOLEM_HIT', 'pitch': 2));
		play_sound(@loc1, array('sound': 'HORSE_BREATHE', 'pitch': 1.7));

		@endtask = closure(){
			if(!entity_grounded(@mover)) {
				set_entity_velocity(@mover, array(0, 0.4, 0));
			}

			if(ponline(@player)) {
				@inv = associative_array();
				@inv[@slot] = null;
				set_pinv(@player, @inv);
				set_timeout(50, closure(){
					@inv[@slot] = array('name': 'FISHING_ROD');
					set_pinv(@player, @inv);
				});
			}
		}
		@task = closure(@interval = true){
			try {
				if(get_entity_health(@shooter) < @startingHealth
				|| get_entity_health(@mover) == 0
				|| pinfo(@player, 15) != @slot
				|| !entity_exists(@hook)) {
					if(@interval) {
						clear_task();
					}
					execute(@endtask);
				} else {
					@loc2 = entity_loc(@target);
					@loc1 = entity_loc(@mover);
					@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));
					@dist = max(0.1, min(20, @dist));
					if(@dist > 2) {
						if(@dist > 10) {
							@pitch = 1.4 + (0.6 * (@dist - 10) / 20);
							play_sound(@loc1, array('sound': 'HORSE_BREATHE', 'pitch': @pitch));
						}
						@x = (@loc2['x'] - @loc1['x']) / @dist;
						@y = (@loc2['y'] - @loc1['y']) / @dist * 1.1;
						@z = (@loc2['z'] - @loc1['z']) / @dist;
						set_entity_velocity(@mover, array(@x, @y, @z));
						set_entity_fall_distance(@mover, 0);
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

	bind(projectile_hit, array('id': 'hit'.@arrow), array('id': @arrow), @event, @shooter, @slot, @hook) {
		_reel(@event['location'], @shooter, @slot, @hook, @event['id'], @shooter);
	}

	bind(entity_damage_player, array('id': 'damage'.@arrow), array('id': @arrow), @event, @shooter, @slot, @hook) {
		@hit = puuid(@event['player']);
		try(set_entity_rider(@hit, @hook));
		_reel(@event['location'], @shooter, @slot, @hit, @shooter, @hit);
	}

	set_timeout(800, closure(){
		if(has_bind('hit'.@arrow)
		&& has_bind('damage'.@player)) {
			try(entity_remove(@arrow));
		}
		unbind('hit'.@arrow);
		unbind('damage'.@arrow);
	});
}
