proc _class_load(@player, @pvp) {
	bind('entity_damage_player', array(id: @player.'werewolf'), null, @e, @p = @player) {
		if(@e['player'] == @p && !is_null(pinv(@p, 103))) {
			play_sound(ploc(@p), array(sound: 'ENTITY_WOLF_HURT', pitch: 0.75));
		} else if(@e['data'] == @p && !is_null(pinv(@p, 103)) && !rand(4)) {
			play_sound(ploc(@p), array(sound: 'ENTITY_WOLF_GROWL', pitch: 0.9));
		}
	}

	bind('player_death', array(id: @player.'kill'), null, @e, @player) {
		if(@e['killer'] == @player && !is_null(pinv(@player, 103))) {
			pgive_item(@player, array(name: 'BEETROOT', meta: array(display: player().'\'s Heart')));
		}
	}
	
	bind('player_consume', array(id: @player.'eat'), array(itemname: 'BEETROOT', player: @player), @event) {
		set_phealth(player(), min(20, phealth() + 2));
	}
}

proc _class_equip(@player) {
	@r = rand(0, 256);
	@g = rand(0, 256);
	@b = rand(0, 256);
	set_pinv(@player, array(
		100: array(name: 'LEATHER_BOOTS', meta: array(color: array(r: @r, g: @g, b: @b))),
		101: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(r: @r, g: @g, b: @b))),
		102: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(r: @r, g: @g, b: @b))),
	));
}

proc _class_powerup(@player) {
	damage_entity(puuid(@player), min(phealth(@player) - 1, 5));
	set_peffect(@player, 'SPEED', 3, 17);
	set_peffect(@player, 'STRENGTH', 1, 17);
	set_peffect(@player, 'JUMP_BOOST', 1, 17);
	set_timeout(1, closure(){ # powerups flash night vision, so we have to delay here
		try {
			set_peffect(@player, 'NIGHT_VISION', 0, 23);
		} catch(PlayerOfflineException @ex) {
			// player logged off last tick, nice timing
		}
	});
	play_sound(ploc(@player), array(sound: 'ENTITY_WOLF_GROWL', pitch: 0.8, volume: 3));
	set_pinv(@player, array(
		100: array(name: 'LEATHER_BOOTS', meta: array(color: array(r: 50, g: 50, b: 50),
			enchants: array(depth_strider: 2))
		),
		101: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(r: 50, g: 50, b: 50))),
		102: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(r: 50, g: 50, b: 50))),
		103: array(name: 'GRAY_WOOL'),
	));
	set_timeout(17000, closure(){
		if(ponline(@player) && pmode(@player) != 'SPECTATOR') {
			play_sound(ploc(@player), array(sound: 'ENTITY_WOLF_PANT', pitch: 0.9));
			@effects = get_peffect(@player);
			if(array_index_exists(@effects, 'night_vision') && @effects['night_vision']['seconds'] < 7) {
				# if there is 6 seconds of night vision left, he has not gotten another powerup
				@r = rand(0, 256);
				@g = rand(0, 256);
				@b = rand(0, 256);
				set_pinv(@player, array(
					100: array(name: 'LEATHER_BOOTS', meta: array(color: array(r: @r, g: @g, b: @b))),
					101: array(name: 'LEATHER_LEGGINGS', meta: array(color: array(r: @r, g: @g, b: @b))),
					102: array(name: 'LEATHER_CHESTPLATE', meta: array(color: array(r: @r, g: @g, b: @b))),
					103: null,
				));
				set_peffect(@player, 'NIGHT_VISION', 0, 0);
			}
		}
	});
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'werewolf');
	unbind(@player.'kill');
	unbind(@player.'eat');
}
