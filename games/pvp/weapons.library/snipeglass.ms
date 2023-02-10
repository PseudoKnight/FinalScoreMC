proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'SPYGLASS', button: 'right'), @event, @pvp) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}
		if(pcooldown('SPYGLASS')) {
			cancel();
			die();
		}
		set_pcooldown('SPYGLASS', 8000 / 50);
		set_pexp(0);
		set_interval(50, closure(){
			try {
				if(!phealth() || pmode() == 'SPECTATOR') {
					clear_task();
				} else {
					@xp = pexp();
					@xp = min(99, @xp + 2);
					set_pexp(@xp);
					if(@xp < 70) {
						play_sound(ploc(), array(sound: 'BLOCK_BEACON_ACTIVATE', pitch: 0.5 + 1.5 * @xp / 70));
					} else if(@xp == 99) {
						clear_task();
						_weapon_hit_scan(player(), array(raySize: 0.1), 16, array(tracer: 'CRIT', hitparticle: 'LAVA'), @pvp);
						play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CURE', pitch: 1.8, volume: 3));
					}
				}
			} catch(Exception @ex) {
				clear_task();
			}
		});
	}
}