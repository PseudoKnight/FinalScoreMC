array_push(@pvp['binds'], @id.'grapple')
bind(player_interact, array('id': @id.'grapple'), array('item': 417, 'button': 'right'), @event, @id) {
	@pvp = import('pvp'.@id);
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	if(has_bind('grapple'.player())) {
		die();
	}

	if(!ptake_item(262, 1)) {
		die();
	}

	@arrow = shoot_projectile(player(), 'arrow');
	@v = entity_velocity(@arrow);
	set_entity_velocity(@arrow, array(@v['x'] * 1.5, @v['y'] * 1.5, @v['z'] * 1.5));
	set_entity_spec(@arrow, array('critical': true));
	play_sound(ploc(), array('sound': 'SHOOT_ARROW'));
	@shooter = puuid();

	bind(projectile_hit, array(id: 'grapple'.player()), array('id': @arrow), @event, @shooter) {
		unbind();

		@loc2 = @event['location'];
		@player = get_player_from_entity_id(@shooter);

		@loc1 = entity_loc(@shooter);

		@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));
		if(@dist > 64) {
			die();
		}

		play_sound(@loc1, array('sound': 'IRONGOLEM_HIT', 'pitch': 2));
		play_sound(@loc2, array('sound': 'IRONGOLEM_HIT', 'pitch': 2));
		play_sound(@loc1, array('sound': 'HORSE_BREATHE', 'pitch': 1.7));

		@squid = spawn_mob('SQUID', 1, @loc2)[0];
		set_mob_effect(@squid, 14, 0, 12, true, false);
		set_mob_effect(@squid, 11, 5, 12, true, false);
		set_leashholder(@squid, @shooter);

		@armorstand = spawn_entity('ARMOR_STAND', 1, _relative(@loc2, 'down', 2.5))[0];
		set_entity_spec(@armorstand, array('gravity': false, 'small': true, 'visible': false));
		set_entity_rider(@armorstand, @squid);

		@grapple = array(time: 0);
		@endtask = closure(){
			if(ponline(@player) && !entity_grounded(@shooter)) {
				set_entity_velocity(@shooter, array(0, 0.4, 0));
			}
			try {
				entity_remove(@armorstand);
				entity_remove(@squid);
			} catch(BadEntityException @e) {
				# entity doesn't exist, moving on
			}
		}
		@task = closure(){
			@grapple['time'] += 1;
			if(!ponline(@player)
			|| get_entity_health(@shooter) <= 0
			|| @grapple['time'] > 100
			|| pinfo(@player, 11)) {
				execute(@endtask);
				clear_task();
			} else {
				try {
					@loc2 = entity_loc(@event['id']);
					@loc1 = entity_loc(@shooter);
					@dist = sqrt(((@loc2['x'] - @loc1['x']) ** 2) + ((@loc2['y'] - @loc1['y']) ** 2) + ((@loc2['z'] - @loc1['z']) ** 2));
					@dist = min(20, @dist);
					@x = (@loc2['x'] - @loc1['x']) / @dist;
					@y = (@loc2['y'] - @loc1['y']) / @dist * 1.1;
					@z = (@loc2['z'] - @loc1['z']) / @dist;
					set_entity_velocity(@shooter, array(@x, @y, @z));
					set_entity_fall_distance(@shooter, 0);
					if(@dist >= 10) {
						@pitch = 1.4 + (0.6 * (@dist - 10) / 20);
						play_sound(@loc1, array('sound': 'HORSE_BREATHE', 'pitch': @pitch));
					}
				} catch(BadEntityException @e){
					execute(@endtask);
					clear_task();
				}
			}
		}
		execute(@task);
		set_interval(100, @task);
	}

	set_timeout(1100, closure(){
		if(has_bind('grapple'.player())) {
			try {
				entity_remove(@arrow);
				unbind('grapple'.player());
			} catch(BadEntityException @e) {
				# entity doesn't exist, moving on
			}
		}
	});
}
