<! 
	author: PseudoKnight,rivergod
>
proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Extinguish yourself!',
		'Put yourself out! You\'re too hot!',
	));
	@blocks = import('frogware.blocks');
	if(is_null(@blocks)) {
		@blocks = array();
		export('frogware.blocks', @blocks);
	}
	@count = _fw_total_players() + 1;
	for(@i = 0, @i < @count, @i++) {
		@loc = _fw_loc();
		@blocks[] = @loc;
		@level = rand(3);
		if(@level) {
			set_blockdata(@loc, array(block: 'water_cauldron', level: @level));
		} else {
			set_block(@loc, 'CAULDRON');
		}
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			set_ponfire(@p, 20 * @secs + 40);
		}
	}
}

proc _fw_end_task(@secs) {
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p) && ponfire(@p) <= 0 && _fw_change_team(@p, 'winners')) {
			play_sound(ploc(@p), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), @p);
		}
	}
}