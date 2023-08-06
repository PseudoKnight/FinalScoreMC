/*
	Block ghast fireball damage to all but natural nether blocks
 */
bind('entity_explode', null, array(type: 'FIREBALL'), @event,
		@breakables = array('NETHERRACK', 'SOUL_SAND', 'GRAVEL', 'MAGMA_BLOCK', 'GLOWSTONE', 'NETHER_QUARTZ_ORE',
		'SOUL_SOIL', 'BONE_BLOCK', 'CRIMSON_NYLIUM', 'NETHER_WART_BLOCK', 'WEEPING_VINES', 'WEEPING_VINES_PLANT',
		'CRIMSON_ROOTS', 'CRIMSON_FUNGUS', 'WARPED_FUNGUS', 'CRIMSON_STEM', 'WARPED_STEM', 'TWISTING_VINES',
		'RED_MUSHROOM', 'BROWN_MUSHROOM', 'BLACKSTONE', 'BASALT', 'NETHER_GOLD_ORE', 'WARPED_NYLIUM',
		'WARPED_ROOTS','NETHER_SPROUTS', 'SHROOMLIGHT')) {

	@world = @event['location']['world'];
	if(_is_survival_world(@world) && @world != 'outworld_nether') {
		@blocks = @event['blocks'];
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