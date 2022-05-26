proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Last hit gets you a point.',
		'Hit others, but don\'t get hit yourself.',
		'PVP round!',
		'It\'s a free-for-all!',
	));
	_fw_random_potion(array('speed', 'jump_boost', 'blindness', 'invisibility'));
	@weapons = array();
	switch(rand(4)) {
		case 0:
			@bow = array(name: 'BOW');
			if(!rand(4)) {
				@bow['meta'] = array(enchants: array(punch: 8));
			}
			@weapons = array(@bow, array(name: 'ARROW', qty: rand(1, 6)));
		case 1:
			@weapons = array(array(name: 'SNOWBALL', qty: rand(1, 4)));
		case 2:
			@weapons = array(array(name: 'CROSSBOW'), array(name: 'ARROW', qty: rand(1, 4)));
		case 3:
			@sword = array(name: 'IRON_SWORD');
			if(!rand(4)) {
				@sword['meta'] = array(enchants: array(knockback: 8));
			}
			@weapons = array(@sword);
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			foreach(@weapon in @weapons) {
				pgive_item(@p, @weapon);
			}
		}
	}
	if(!rand(3)) {
		@blocks = import('frogware.blocks');
		if(is_null(@blocks)) {
			@blocks = array();
		}
		@region = sk_region_info('frogware', 'custom', 0);
		@minX = @region[1][0];
		@maxX = @region[0][0];
		@minZ = @region[1][2];
		@maxZ = @region[0][2];
		@minY = @region[1][1];
		@maxY = @region[1][1] + 3;
		for(@x = @minX, @x <= @maxX, @x++) {
			for(@z = @minZ, @z <= @maxZ, @z++) {
				if(rand() < 0.07) {
					for(@y = @minY, @y < @maxY, @y++) {
						@block = array(@x, @y, @z, 'custom');
						set_block(@block, 'GRAY_CONCRETE');
						@blocks[] = @block;
					}
				}
			}
		}
		export('frogware.blocks', @blocks);
	}
	bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', world: 'custom'), @e, @weapons) {
		if(array_index_exists(@e, 'damager') && _fw_player(@e['player'])) {
			@damager = @e['damager'];
			if(array_index_exists(@e, 'shooter')) {
				@damager = @e['shooter'];
			}
			if(_fw_player(@damager) && (@weapons[0]['name'] == 'IRON_SWORD' || array_index_exists(@e, 'shooter'))) {
				if(_fw_change_team(@damager, 'winners')) {
					play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
				}
				if(_fw_change_team(@e['player'], 'losers')) {
					play_sound(ploc(@e['player']), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @e['player']);
				}
			}
		}
	}
}

proc _fw_end_task(@secs) {
	_fw_clear_effects();
}