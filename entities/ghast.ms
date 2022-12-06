/*
	Grant Uneasy Alliance advancement in non-default worlds
 */
bind('entity_death', null, array(type: 'GHAST'), @event) {
	if(world_info(@event['location']['world'])['environment'] == 'NORMAL'
			&& _is_survival_world(@event['location']['world'])) {
		@damager = '';
		if(array_index_exists(@event['cause'], 'shooter')) {
			@damager = @event['cause']['shooter'];
		} else if(array_index_exists(@event['cause'], 'damager')) {
			@damager = @event['cause']['damager'];
		}
		if(ponline(@damager)) {
			@player = player(@damager);
			runas('~console', "/advancement grant @player only minecraft:nether/uneasy_alliance");
		}
	}
}

/*
	Block ghast fireball damage to all but natural nether blocks
 */
bind('entity_explode', null, array(type: 'FIREBALL'), @event) {
	@world = @event['location']['world'];
	if(_is_survival_world(@world) && @world != 'outworld_nether') {
		@blocks = @event['blocks'];
		@breakables = array('NETHERRACK', 'SOUL_SAND', 'GRAVEL', 'MAGMA_BLOCK', 'GLOWSTONE', 'NETHER_QUARTZ_ORE',
			'SOUL_SOIL', 'BONE_BLOCK', 'CRIMSON_NYLIUM', 'NETHER_WART_BLOCK', 'WEEPING_VINES', 'WEEPING_VINES_PLANT',
			'CRIMSON_ROOTS', 'CRIMSON_FUNGUS', 'WARPED_FUNGUS', 'CRIMSON_STEM', 'WARPED_STEM', 'TWISTING_VINES',
			'RED_MUSHROOM', 'BROWN_MUSHROOM', 'BLACKSTONE', 'BASALT', 'NETHER_GOLD_ORE', 'WARPED_NYLIUM',
			'WARPED_ROOTS','NETHER_SPROUTS', 'SHROOMLIGHT');
		@modify = false;
		foreach(@index: @block in @blocks) {
			if(!array_contains(@breakables, get_block(@block))) {
				array_remove(@blocks, @index);
				@modify = true;
			}
		}
		if(@modify) {
			modify_event('blocks', @blocks);
		}
	}
}