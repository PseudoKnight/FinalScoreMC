proc _fw_start_task(@secs) {
	@ores = array( 
		'EMERALD_ORE',
		'DIAMOND_ORE',
		'IRON_ORE',
		'GOLD_ORE',
		'LAPIS_ORE'
	);
	@ore = array_get_rand(@ores);
	_fw_msg('Mine three of '.@ore);
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'DIAMOND_PICKAXE', meta: array(enchants: array(efficiency: 6))));
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	@minX = @region[1][0];
	@maxX = @region[0][0];
	@minY = @region[1][1];
	@minZ = @region[1][2];
	@maxZ = @region[0][2];
	for(@y = @minY, @y <= @minY + 2, @y++) {
		queue_delay(500, 'fw3');
		queue_push(closure(){
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					relative_teleport(@p, location_shift(ploc(), 'up', 2));
				}
			}
			for(@x = @minX, @x <= @maxX, @x++) {
				for(@z = @minZ, @z <= @maxZ, @z++) {
					if(@y == @minY + 2 || rand(16)) {
						set_block(array(@x, @y, @z, 'custom'), 'STONE');
					} else if(rand(3)) {
						set_block(array(@x, @y, @z, 'custom'), array_get_rand(@ores));
					} else {
						set_block(array(@x, @y, @z, 'custom'), @ore);
					}
				}
			}
		}, 'fw3');
	}
	@count = associative_array();
	bind('block_break', array(id: 'fwtask'), null, @e, @count, @ore) {
		if(_fw_player(player())) {
			if(@e['block'] == @ore) {
				@count[player()] = array_get(@count, player(), 0) + 1;
				if(@count[player()] == 3 && _fw_changeteam(player(), 'winners')) {
					play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
				}
			} else if(!array_contains(sk_regions_at(@e['location']), 'frogware')) {
				cancel();
			}
		}
	}
}

proc _fw_end_task(@secs) {
	_fw_clear_blocks(3);
	_remove_region_entities('frogware', array('DROPPED_ITEM'));
}