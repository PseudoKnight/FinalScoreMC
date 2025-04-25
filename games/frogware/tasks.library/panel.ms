proc _fw_start_task(@secs) {
	@colors = array( // block : chat
		WHITE: 'WHITE',
		ORANGE: 'GOLD',
		MAGENTA: 'LIGHT_PURPLE',
		BLUE: 'DARK_BLUE',
		YELLOW: 'YELLOW',
		LIME: 'GREEN',
		PINK: 'RED',
		GRAY: 'DARK_GRAY',
		LIGHT_GRAY: 'GRAY',
		CYAN: 'AQUA',
		PURPLE: 'DARK_PURPLE',
		LIGHT_BLUE: 'BLUE',
		GREEN: 'DARK_GREEN',
		RED: 'DARK_RED',
		BLACK: 'BLACK',
		BROWN: 'k',
	);
	@blockcolor = array_rand(@colors, 1)[0];
	@chatcolor = @colors[@blockcolor];
	_fw_msg('Stand on '.@blockcolor);
	export('panel', @blockcolor);
	@region = sk_region_info('frogware', 'custom', 0);
	@minX = @region[1][0];
	@maxX = @region[0][0];
	@y = @region[1][1] - 1;
	@minZ = @region[1][2];
	@maxZ = @region[0][2];
	@paintfloor = closure(@task = true) {
		if(@task) {
			play_sound(array(@minX, @y, @minZ, 'custom'), array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2));
		}
		@grid = array();
		for(@i = 0, @i < 7, @i++) {
			@grid[@i] = array();
			for(@j = 0, @j < 7, @j++) {
				@grid[@i][@j] = array_rand(@colors, 1)[0];
			}
		}
		for(@x = @minX + 1, @x < @maxX, @x++) {
			for(@z = @minZ + 1, @z < @maxZ, @z++) {
				@c = @grid[min(6, integer((@x - @minX) / 5))][min(6, integer((@z - @minZ) / 5))];
				if(@x % 2 < 1 && @z % 2 < 1) {
					set_block(array(@x, @y, @z, 'custom'), @c.'_GLAZED_TERRACOTTA', false);
				} else {
					set_block(array(@x, @y, @z, 'custom'), @c.'_CONCRETE', false);
				}
			}
		}
	}
	execute(false, @paintfloor);
	if(!rand(5)) {
		set_timeout(3000, @paintfloor);
	}
}

proc _fw_end_task(@secs) {
	@target = import('panel');
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			if(string_starts_with(get_block(ploc(@p)), @target)
			&& _fw_change_team(@p, 'winners')) {
				play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
			}
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	@minX = @region[1][0];
	@maxX = @region[0][0];
	@y = @region[1][1] - 1;
	@minZ = @region[1][2];
	@maxZ = @region[0][2];
	for(@x = @minX + 1, @x < @maxX, @x++) {
		for(@z = @minZ + 1, @z < @maxZ, @z++) {
			set_block(array(@x, @y, @z, 'custom'), 'WHITE_CONCRETE', false);
		}
	}
	export('panel', null);
}