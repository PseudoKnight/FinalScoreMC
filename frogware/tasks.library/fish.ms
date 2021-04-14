proc _fw_start_task(@secs) {
	_fw_msg(array(
		'Catch a thing!',
		'Reel it in!',
		'Catch a frog or a pig... Either.',
	));
	foreach(@p in all_players('custom')) {
		if(_fw_player(@p)) {
			pgive_item(@p, array(name: 'FISHING_ROD', meta: array(damage: 60)));
		}
	}
	@region = sk_region_info('frogware', 'custom', 0);
	bind('player_fish', array(id: 'fwtask'), array(state: '/(CAUGHT_ENTITY|CAUGHT_FISH)/'), @e) {
		if(_fw_player(@e['player'])) {
			if(_fw_changeteam(player(), 'winners')) {
				play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_ATTACK_IRON_DOOR'), player());
			}
		}
	}
	if(!rand(5)) {
		set_timeout(2000, closure(){
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					@item = pinv(@p, null);
					if(@item) {
						play_sound(ploc(@p), array(sound: 'entity_witch_ambient', volume: 4, pitch: 1.2), @p);
						set_pinv(@p, null, null);
						drop_item(@p, @item);
					}
				}
			}
		});
	}
}

proc _fw_end_task(@secs) {
	
}