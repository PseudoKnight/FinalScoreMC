proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Last hit gets you a point.',
		'Hit others, but don\'t get hit yourself.',
		'PVP round!',
		'It\'s a free-for-all!',
	));
	_fw_randompotion(array('speed', 'jump', 'blind', 'invis'));
	@weapon = array(name: 'IRON_SWORD', meta: array(damage: 226));
	switch(rand(3)) {
		case 0:
			@weapon = array(name: 'BOW', meta: array(damage: 379));
		case 1:
			@weapon = array(name: 'SNOW_BALL');
	}
	@meta = null;
	if(!rand(4)) {
		@weapon['meta'] = array(enchants: array(knockback: 8, punch: 8));
	}
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, @weapon);
			if(@weapon['name'] == 'BOW') {
				pgive_item(@p, array(name: 'ARROW', qty: 10));
			}
		}
	}
	bind('entity_damage', array(id: 'fwtask'), array(type: 'PLAYER', world: 'custom'), @e, @weapon) {
		if(array_index_exists(@e, 'damager') && _fw_player(@e['player'])) {
			@damager = @e['damager'];
			if(array_index_exists(@e, 'shooter')) {
				@damager = @e['shooter'];
			}
			if(_fw_player(@damager) && (@weapon['name'] == 'IRON_SWORD' || array_index_exists(@e, 'shooter'))) {
				if(_fw_changeteam(@damager, 'winners')) {
					play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
				}
				if(_fw_changeteam(@e['player'], 'losers')) {
					play_sound(ploc(@e['player']), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED'), @e['player']);
				}
			}
		}
	}
}

proc _fw_end_task(@secs) {
	_fw_clear_effects();
}