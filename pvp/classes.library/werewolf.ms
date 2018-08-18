switch(@action) {
case 'load':
	bind('entity_damage_player', array('id': @player.'werewolf'), null, @e, @p = @player) {
		if(@e['player'] == @p && !is_null(pinv(@p, 103))) {
			play_sound(ploc(@p), array('sound': 'ENTITY_WOLF_HURT', 'pitch': 0.75))
		} else if(@e['data'] == @p && !is_null(pinv(@p, 103)) && !rand(4)) {
			play_sound(ploc(@p), array('sound': 'ENTITY_WOLF_GROWL', 'pitch': 0.9))
		}
	}

	bind('player_death', array('id': @player.'kill'), null, @e, @player) {
		if(@e['killer'] == @player && !is_null(pinv(@player, 103))) {
			pgive_item(@player, array('name': 'FERMENTED_SPIDER_EYE', 'meta': array('display': player().'\'s Heart')));
		}
	}
	
	bind('player_interact', array('id': @player.'eat'), array('button': 'right', 'itemname': 'FERMENTED_SPIDER_EYE', 'player': @player), @event) {
		ptake_item(array('name': 'FERMENTED_SPIDER_EYE'));
		set_phealth(player(), min(20, phealth() + 4));
		play_sound(ploc(), array('sound': 'ENTITY_GENERIC_EAT', 'pitch': 0.5));
		spawn_particle(location_shift(ploc(), 'up', 2), array('particle': 'BLOCK_DUST', 'count': 10, 'block': 'NETHER_WART_BLOCK', 'speed': 0.1))
		set_timeout(500, closure(){
			set_phealth(player(), min(20, phealth() + 4));
			play_sound(ploc(), array('sound': 'ENTITY_GENERIC_EAT', 'pitch': 0.5));
			spawn_particle(location_shift(ploc(), 'up', 2), array('particle': 'BLOCK_DUST', 'count': 10, 'block': 'NETHER_WART_BLOCK', 'speed': 0.1))
		});
	}

case 'equip':
	@r = rand(0, 256);
	@g = rand(0, 256);
	@b = rand(0, 256);
	set_pinv(@player, array(
		100: array('name': 'LEATHER_BOOTS', 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
		101: array('name': 'LEATHER_LEGGINGS', 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
		102: array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
	));
	queue_clear(@player.'evolve');

case 'powerup':
	damage_entity(puuid(@player), min(phealth(@player) - 1, 5));
	set_peffect(@player, 1, 3, 17);
	set_peffect(@player, 5, 1, 17);
	set_peffect(@player, 8, 1, 17);
	set_timeout(50, closure(){ # powerups flash night vision, so we have to delay here
		try {
			set_peffect(@player, 16, 0, 23);
		} catch(PlayerOfflineException @ex) {
			// player logged off last tick, nice timing
		}
	});
	play_sound(ploc(@player), array('sound': 'ENTITY_WOLF_HOWL', 'pitch': 0.9, 'volume': 3));
	set_pinv(@player, array(
		100: array('name': 'LEATHER_BOOTS', 'meta': array('color': array('r': 50, 'g': 50, 'b': 50)),
			'enchants': array(array('elevel': 2, 'etype': 'DEPTH_STRIDER'))
		),
		101: array('name': 'LEATHER_LEGGINGS', 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
		102: array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': array('r': 50, 'g': 50, 'b': 50))),
		103: array('name': 'WOOL', 'data': 7),
	));
	set_timeout(17000, closure(){
		if(ponline(@player) && pmode(@player) != 'SPECTATOR') {
			foreach(@effect in get_peffect(@player)) {
				# if there's 6 seconds of night vision left, he hasn't gotten another powerup
				if(@effect['id'] == 16 && @effect['seconds'] < 7) {
					@r = rand(0, 256);
					@g = rand(0, 256);
					@b = rand(0, 256);
					set_pinv(@player, array(
						100: array('name': 'LEATHER_BOOTS', 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
						101: array('name': 'LEATHER_LEGGINGS', 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
						102: array('name': 'LEATHER_CHESTPLATE', 'meta': array('color': array('r': @r, 'g': @g, 'b': @b))),
						103: null,
					));
					set_peffect(@player, 16, 0, 0);
				}
			}
		}
	});

case 'unload':
	unbind(@player.'werewolf');
	unbind(@player.'kill');
	unbind(@player.'eat');

}
