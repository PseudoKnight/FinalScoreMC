switch(@action) {
case 'load':
	bind(player_interact, array('id': @player.'plasmagun'), array('item': 382, 'button': 'right', 'player': @player), @e) {
		if(pinfo(player(), 6) != @e['item']) {
			die();
		}
		cancel();
		if(pexp() == 99) {
			@arrow = shoot_projectile(player(), 'ARROW');
			set_entity_onfire(@arrow, 1);
			set_entity_gravity(@arrow, false);
			play_sound(ploc(), array('sound': 'ENDERDRAGON_HIT', 'pitch': 2, 'volume': 2));
			set_pexp(0);
			set_interval(50, closure(){
				try {
					@xp = pexp();
					@xp = min(99, @xp + 2);
					set_pexp(@xp);
					if(@xp == 99) {
						clear_task();
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
			set_timeout(800, closure(){
				try(entity_remove(@arrow));
			});
			if(extension_exists('CHSpigot')) {
				@dmg = get_arrow_damage(@arrow);
				set_arrow_damage(@arrow, @dmg * 0.55);
			}
		}
	}

	bind(projectile_hit, array('id': @player.'hit'), array('type': 'ARROW'), @e, @shooter = puuid(@player)) {
		if(@e['shooter'] == @shooter) {
			play_effect(@e['location'], 'LAVA_POP', array('particleCount': 7, 'radius': 96));
			play_sound(@e['location'], array('sound': 'NOTE_BASS_DRUM', 'pitch': 2, 'volume': 2));
			play_sound(@e['location'], array('sound': 'FIZZ', 'pitch': 2, 'volume': 2));
			try(entity_remove(@e['id']));
		}
	}

	bind(player_interact, array('id': @player.'teleport'), array('item': 381, 'player': @player, 'button': 'right'), @e, @pvp) {
		if(pinfo(player(), 6) != @e['item']) {
			die();
		}
		cancel();
		@players = _weapon_hit_scan(player(), 96, 1, array('tracerparticle': 'happy_villager', 'hitparticle': 'ender_signal'), @pvp);

		if(@players) {
			@player = @players[0];
			@loc1 = ploc();
			@facing1 = pfacing();
			@loc2 = ploc(@player);
			@facing2 = pfacing(@player);

			// keep facing the same direction
			@loc1['yaw'] = @facing2[0];
			@loc1['pitch'] = @facing2[1];
			@loc2['yaw'] = @facing1[0];
			@loc2['pitch'] = @facing1[1];

			set_ploc(@loc2);
			damage_entity(puuid(), 1, puuid());
			set_ploc(@player, @loc1);
			play_sound(@loc2, array('sound': 'ENDERMAN_TELEPORT', 'pitch': 0.5));
			play_sound(@loc1, array('sound': 'ENDERMAN_TELEPORT', 'pitch': 0.5));
			make_effect(location_shift(@loc1, 'up', 2), 'ENDER_SIGNAL');
		}

		play_named_sound(ploc(), array('sound': 'entity.elder_guardian.hurt', 'pitch': 2));
		try {
			@item = pinv(player(), null);
			@item['qty']--;
			set_pinv(player(), null, @item);
		} catch(CastException @ex) {
			// Player is probably dead.
		}
	}

case 'powerup':
	set_pexp(@player, 99);

case 'unload':
	unbind(@player.'plasmagun');
	unbind(@player.'hit');
	unbind(@player.'teleport');

}
