proc _fw_start_task(@secs) {
	@types = array(
		'REDSTONE_ORE': 0.005,
		'FARMLAND': 0.005,
		'BIG_DRIPLEAF': 0.005,
		'STONE_PRESSURE_PLATE': 0.003,
	);
	@chosen = array_rand(@types, 2);
	@type = @chosen[0];
	@fake = @chosen[1];
	@ratio = @types[@type];
	_fw_msg(array(
		'Stomp on '.@type,
	));
	@blocks = import('frogware.blocks');
	if(is_null(@blocks)) {
		@blocks = array();
	}
	@region = sk_region_info('frogware', 'custom', 0);
	@minX = @region[1][0] + 1;
	@maxX = @region[0][0] - 1;
	@minZ = @region[1][2] + 1;
	@maxZ = @region[0][2] - 1;
	@minY = @region[1][1];
	@maxY = @region[1][1] + 2;
	for(@x = @minX, @x <= @maxX, @x++) {
		for(@z = @minZ, @z <= @maxZ, @z++) {
			if(rand() < 0.09) {
				for(@y = @minY, @y < @maxY, @y++) {
					@block = array(@x, @y, @z, 'custom');
					set_block(@block, 'STONE', false);
					@blocks[] = @block;
				}
			} else if(rand() < @ratio) {
				if(@type == 'BIG_DRIPLEAF' && @fake != 'STONE_PRESSURE_PLATE') {
					for(@y = @minY, @y < @maxY, @y++) {
						@block = array(@x, @y, @z, 'custom');
						set_block(@block, 'BIG_DRIPLEAF_STEM', false);
						@blocks[] = @block;
					}
					@block = array(@x, @maxY, @z, 'custom');
					set_block(array(@x, @maxY, @z, 'custom'), 'BIG_DRIPLEAF', false);
					@blocks[] = @block;
				} else {
					@block = array(@x, @minY, @z, 'custom');
					set_block(@block, @type, false);
					@blocks[] = @block;
				}
			} else if(rand() < 0.004) {
				@block = array(@x, @minY, @z, 'custom');
				set_block(@block, @fake, false);
				@blocks[] = @block;
			}
			if(rand() < 0.2) {
				@block = array(@x, @minY - 1, @z, 'custom');
				set_block(@block, 'STONE', false);
				@blocks[] = @block;
			}
		}
	}
	export('frogware.blocks', @blocks);

	bind('pressure_plate_activated', array(id: 'fwtask'), null, @event, @type) {
		@block = get_block(@event['location']);
		if(@block == @type) {
			if(@block == 'REDSTONE_ORE') {
				if(get_blockdata(@event['location'])['lit']) {
					die();
				}
			} else if(@block == 'FARMLAND') {
				set_timeout(10, closure(){
					set_block(@event['location'], 'DIRT');
				});
			}
			if(_fw_player(player())) {
				if(_fw_change_team(player(), 'winners')) {
					play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
				}
			}
		}
	}
}

proc _fw_end_task(@secs) {

}