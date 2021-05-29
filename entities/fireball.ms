// Block ghast fireball damage to all but natural nether blocks
bind('entity_explode', null, array('type': 'FIREBALL'), @event) {
	@world = @event['location']['world'];
	if(_is_survival_world(@world) && @world != 'outworld_nether') {
		@blocks = @event['blocks'];
		@breakables = array('NETHERRACK', 'SOUL_SAND', 'GRAVEL', 'MAGMA_BLOCK', 'GLOWSTONE', 'NETHER_QUARTZ_ORE');
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