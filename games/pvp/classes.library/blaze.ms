proc _class_load(@player, @pvp) {
	@pvp['players'][@player]['task'] = set_interval(50, closure(){
		try {
			if(!pcooldown(@player, 'BLAZE_ROD')) {
				spawn_particle(location_shift(ploc(@player), 'up', 2), array(
					particle: 'FLAME',
					xoffset: 0.6,
					yoffset: 1.5,
					zoffset: 0.6,
					count: 2
				));
				if(!rand(8)) {
					play_sound(ploc(@player), array(sound: 'BLOCK_FIRE_AMBIENT'));
				}
			}
		} catch(Exception @ex) {
			clear_task();
			console(@ex);
		}
	});

	bind('player_interact', array(id: @player.'blaze'), array(player: @player, itemname: 'BLAZE_ROD', button: 'right'), @event) {
		if(!pcooldown('BLAZE_ROD')) {
			shoot_projectile(player(), 'SMALL_FIREBALL');
			play_named_sound(ploc(), array(sound: 'entity.blaze.shoot'));
			set_pcooldown('BLAZE_ROD', 118);
			set_timeout(450, closure(){
				if(pmode() != 'SPECTATOR') {
					shoot_projectile(player(), 'SMALL_FIREBALL');
					play_named_sound(ploc(), array(sound: 'entity.blaze.shoot'));
					set_timeout(450, closure(){
						if(pmode() != 'SPECTATOR') {
							shoot_projectile(player(), 'SMALL_FIREBALL');
							play_named_sound(ploc(), array(sound: 'entity.blaze.shoot'));
						}
					});
				}
			});
		}
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'blaze');
	clear_task(@pvp['players'][@player]['task']);
}