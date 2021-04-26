switch(@action) {
case 'load':
	bind('player_interact', array(id: @player.'interact'), array(player: @player, button: 'right', itemname: 'NETHER_STAR'), @e) {
		if(@e['block'] !== 'STONE_BUTTON' && pexp() == 99) {
			cancel();
			@arrow = shoot_projectile(player(), 'ARROW');
			@velocity = entity_velocity(@arrow);
			set_entity_velocity(@arrow, array(@velocity['x'], @velocity['y'], @velocity['z']));
			set_entity_onfire(@arrow, 1);
			play_sound(ploc(), array(sound: 'ENTITY_ENDER_DRAGON_HURT', pitch: 2));
			set_pexp(0);
			set_timeout(450, closure(){
				if(ponline(player()) && pmode() != 'SPECTATOR') {
					set_pexp(99);
				}
			});
		}
	}
	bind('projectile_hit', array(id: @player.'hit'), array(type: 'ARROW'), @e, @shooter = puuid(@player)) {
		if(@e['shooter'] == @shooter && entity_type(@e['id'])) {
			entity_remove(@e['id']);
		}
	}
	bind('entity_damage', array(id: @player.'damage'), array(cause: 'PROJECTILE'), @e, @p = @player) {
		if(@e['shooter'] == @p) {
			modify_event('amount', 28);
		}
	}
	bind('player_death', array(id: @player.'death'), array(player: @player), @e) {
		play_sound(ploc(), array(sound: 'ENTITY_ZOMBIE_VILLAGER_CONVERTED', pitch: 1, volume: 3));
	}

case 'unload':
	unbind(@player.'interact');
	unbind(@player.'hit');
	unbind(@player.'damage');
	unbind(@player.'death');

}
