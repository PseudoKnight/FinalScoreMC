proc _weapon_bind_events(@pvp) {
	@pvp['binds'][] = bind('player_interact', null, array(itemname: 'FIRE_CHARGE', button: 'right'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || pinfo(player(), 6) != @e['item']['name']) {
			die();
		}
		cancel();
		@entity = shoot_projectile(player(), 'FIREBALL');

		play_sound(ploc(), array(sound: 'ENTITY_GHAST_SHOOT', volume: 2));
		_weapon_cooldown(player(), 1000, 'FIREWORK_STAR', closure(){
			play_sound(ploc(), array(sound: 'BLOCK_FIRE_EXTINGUISH', pitch: 1.5));
		});
	}
}
