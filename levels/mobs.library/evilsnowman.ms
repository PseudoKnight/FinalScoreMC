proc _load_mob(@level) {
	bind(entity_damage_player, array('id': 'level'.@level['region'].'evilsnowman'), array('damager': 'SNOWBALL'), @e, @level) {
		@player = @e['player'];
		@damager = @e['data'];
		if(!array_contains(@level['players'], @player)) {
			die();
		}
		@loc = _relative(ploc(@player), 'up', 2);
		play_effect(@loc, 'SNOWBALL_BREAK', associative_array(
			'particleCount': 20,
			'offsetX': 0.5,
			'offsetY': 1,
			'offsetZ': 0.5,
		));
		play_named_sound(@loc, associative_array('sound': 'entity.llama.spit', 'pitch': 0.5));
		damage_entity(puuid(@player), 2);
	}
}

proc _unload_mob(@level) {
	unbind('level'.@level['region'].'evilsnowman');
}
