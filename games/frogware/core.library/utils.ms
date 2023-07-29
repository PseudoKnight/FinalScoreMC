proc _fw_loc(@height = 0, @minrange = false) {
	@region = sk_region_info('frogware', 'custom', 0);
	@return = 1;
	@loc = array(
		@region[0][0] - rand(sqrt((@region[0][0] - @region[1][0]) ** 2)) + 0.5,
		@region[1][1] + @height,
		@region[0][2] - rand(sqrt((@region[0][2] - @region[1][2]) ** 2)) + 0.5,
		'custom'
	);
	if(@minrange) {
		foreach(@p in all_players('custom')) {
			if(!ponline(@p)) {
				continue();
			}
			if(get_pscoreboard(@p) === 'fw'
			&& distance(ploc(@p), @loc) < 6) {
				@return = 0;
				break();
			}
		}
	}
	if(@return == 1) {
		return(@loc);
	}
	return(null);
}

proc _fw_mobs(@mob = 'random', @num = 'random') {
	if(@mob == 'random') {
		@mobs = array('creeper', 'zombie', 'silverfish', 'slime', 'magma_cube', 'zombified_piglin', 'shulker', 'ghast',
				'blaze', 'husk', 'polar_bear', 'vindicator', 'evoker', 'vex', 'ravager', 'bee', 'zoglin', 'warden');
		@mob = array_get_rand(@mobs);
	}
	@height = 0;
	if(@num == 'random') {
		if(@mob == 'ghast') {
			@num = rand(3, 9);
			@height = 24;
		} else if(@mob == 'blaze') {
			@num = rand(10, 20);
			@height = 18;
		} else if(@mob == 'shulker') {
			@num = rand(15, 25);
		} else if(@mob == 'ravager') {
			@num = rand(6, 12);
		} else if(@mob == 'zoglin') {
			@num = rand(16, 32);
		} else if(@mob == 'warden') {
			@num = rand(1, 4);
		} else {
			@num = rand(25, 50);
		}
	}
	@entities = array();
	@types = null; // define generic list for caching in loop
	for(@i = 0, @i < @num, @i++) {
		if(@loc = _fw_loc(@height, true)) {
			@m = _spawn_entity(@mob, @loc);
			@entities[] = @m;
			if(@mob == 'wolf') {
				set_entity_spec(@m, array(angry: true));
				set_mob_target(@m, puuid(_fw_leader()));
			} else if(@mob == 'polarbear' && !rand(8)) {
				set_mob_age(@m, -3000);
			} else if(@mob == 'villager') {
				if(!@types) {
					@types = reflect_pull('enum', 'Profession');
				}
				set_entity_spec(@m, array(profession: array_get_rand(@types), level: 2));
			} else if(@mob == 'bee' || @mob == 'zombified_piglin') {
				set_entity_spec(@m, array(anger: 9999));
				@players = players_in_radius(@loc, 16);
				if(@players) {
					set_mob_target(@m, puuid(array_get_rand(@players)));
				}
			}
		}
	}
	if(!rand(4)) {
		queue_push(closure(){
			foreach(@entity in @entities) {
				try(set_mob_effect(@entity, 'speed', rand(2), 15, true))
			}
		})
	}
}

proc _fw_items(@item, @num) {
	for(@i = 0, @i < @num, @i++) {
		if(@loc = _fw_loc()) {
			drop_item(@loc, @item);
		}
	}
}

#Given two blocks, iterates through all the blocks inside the cuboid, and calls the
#user defined function on them. The used defined procedure should accept 3 parameters,
#the x, y, and z coordinates of the block.
proc _iterate_cuboid(@b1, @b2, @block, @percent) {
	@blocks = import('frogware.blocks');
	if(is_null(@blocks)) {
		@blocks = array();
	}

	@region = sk_region_info('frogware', 'custom', 0);
	@minX = max(@region[1][0], min(@b1[0], @b2[0]));
	@maxX = min(@region[0][0], max(@b1[0], @b2[0]));
	@minY = min(@b1[1], @b2[1]);
	@maxY = max(@b1[1], @b2[1]);
	@minZ = max(@region[1][2], min(@b1[2], @b2[2]));
	@maxZ = min(@region[0][2], max(@b1[2], @b2[2]));

	@count = 0;
	for(@x = @minX, @x <= @maxX, @x++) {
		for(@y = @minY, @y <= @maxY, @y++) {
			for(@z = @minZ, @z <= @maxZ, @z++) {
				if(rand(100) < @percent) {
					set_block(array(@x, @y, @z, 'custom'), @block);
					if(@block != 'ANVIL') {
						@blocks[] = array(@x, @y, @z, 'custom');
					}
				}
				if(@count++ > 5000) {
					console('Warning: _iterate_cuboid logic potentially caused infinite loop.');
					break(3);
				}
			}
		}
	}
	if(@block != 'AIR') {
		export('frogware.blocks', @blocks);
	}
}

proc _fw_clear_blocks(@height = 1) {
	@region = sk_region_info('frogware', 'custom', 0);
	_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
		array(@region[1][0], @region[1][1] + @height - 1, @region[1][2], 'custom'),
		'AIR', 100);
}

proc _fw_msg(@msg) {
	if(is_array(@msg)) {
		@msg = array_get_rand(@msg);
	}
	update_bar('fw', array(title: @msg));
}
