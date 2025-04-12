proc _class_load(@player, @pvp) {
	bind('player_interact', array(id: @player.'interact'), array(player: @player, button: 'right', itemname: 'IRON_HOE', hand: 'main_hand'), @e) {
		cancel();
		if(get_block(ploc()) === 'AIR' || phunger() == 0) {
			die();
		}
		@facing = pfacing(player());
		@facing[0] = @facing[0] + 90;
		@facing[1] = 0 - @facing[1];
		@x = 1.40 * cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		@y = max((1.40 * sin(to_radians(@facing[1]))) + 0.2, 0.2);
		@z = 1.40 * sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
		set_pvelocity(player(), @x, @y, @z);
		play_sound(ploc(), array(sound: 'ENTITY_GHAST_WARN', pitch: 2, volume: 2));
		set_timeout(1, closure(){
			set_pvelocity(player(), @x, @y, @z);
			if(psaturation() >= 1) {
				set_psaturation(psaturation() - 1);
			} else if(phunger() >= 1) {
				set_phunger(phunger() - 1);
			}
		});
	}
	bind('entity_damage', array(id: @player.'falldamage'), array(type: 'PLAYER', cause: 'FALL'), @e, @p = @player) {
		if(@e['player'] == @p) {
			cancel();	
		}
	}
	bind('entity_damage', array(id: @player.'damage'), array(type: 'PLAYER', cause: 'ENTITY_ATTACK'), @e, @p = @player) {
		if(@e['damager'] == @p) {
			@helm = pinv(@e['player'], 103);
			if(@helm && @helm['name'] == 'GLASS') {
				modify_event('amount', 13);
			} else {
				modify_event('amount', 4);
			}
		} else if(@e['player'] == @p
		&& @e['damagertype'] === 'ZOMBIE') {
			cancel();
		}
	}
	bind('player_death', array(id: @player.'death'), array(player: @player), @e) {
		play_sound(ploc(), array(sound: 'ENTITY_GHAST_DEATH', pitch: 0));
	}

	proc _manti_noise(@player) {
		if(ponline(@player)) {
			if(pmode(@player) != 'SPECTATOR') {
				play_sound(ploc(@player), array(sound: 'ENTITY_CAT_PURREOW', pitch: 0, volume: 2));
			}
			queue_delay(1000 * rand(6, 18), @player);
			queue_push(closure(_manti_noise(@player)), @player);
		}
	}
	_manti_noise(@player);
}

proc _class_powerup(@player) {
	set_phunger(@player, min(20, phunger(@player) + 4));
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'interact');
	unbind(@player.'falldamage');
	unbind(@player.'damage');
	unbind(@player.'death');
	queue_clear(@player);
}
