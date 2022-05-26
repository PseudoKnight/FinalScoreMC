proc _fw_start_task(@secs) {
	@colors = array('RED': array(255, 0, 0), 'YELLOW': array(255, 255, 0), 'BLUE': array(0, 0, 255));
	@clothing = array(leggings: null, boots: null, helmet: null, chestplate: null);
	@num = rand(1, 3);
	@string = '';
	while(@num-- > 0) {
		@type = array_rand(@clothing)[0];
		if(!@clothing[@type]) {
			@color = array_rand(@colors)[0];
			@clothing[@type] = @colors[@color];
			if(@string) {
				@string .= ' and ';
			}
			@string .= _to_upper_camel_case(@color.' '.@type);
		}
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			title(@p, 'Wear the following:', @string, 0, 80, 40);
		}
	}
	// drop the desired items first
	@count = _fw_total_players() * 2;
	for(@i = 0, @i < @count, @i++) {
		foreach(@type: @color in @clothing) {
			if(@color) {
				drop_item(_fw_loc(), array(name: 'LEATHER_'.to_upper(@type), meta: array(color: @color)));
			}
		}
	}
	// now drop some random items
	@count *= 2;
	for(@i = 0, @i < @count, @i++) {
		foreach(@type: @color in @clothing) {
			drop_item(_fw_loc(), array(name: 'LEATHER_'.to_upper(@type), meta: array(color: array_get_rand(@colors))));
		}
	}
	bind('player_armor_change', array(id: 'fwtask'), null, @event, @clothing) {
		if(_fw_player(player())) {
			@equipment = get_mob_equipment(puuid());
			foreach(@type: @color in @clothing) {
				if(@color == null) {
					if(@equipment[@type] != null) {
						die();
					}
				} else if(@equipment[@type] == null) {
					if(@color != null) {
						die();
					}
				} else if(!@equipment[@type]['meta'] || !array_index_exists(@equipment[@type]['meta'], 'color')) {
					die();
				} else {
					@c = @equipment[@type]['meta']['color'];
					if(!@c || @c['r'] != @color[0] || @c['g'] != @color[1] || @c['b'] != @color[2]) {
						die();
					}
				}
			}
			if(_fw_change_team(player(), 'winners')) {
				play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
			}
		}
	}
}

proc _fw_end_task(@secs) {
	_remove_region_entities('frogware');
}