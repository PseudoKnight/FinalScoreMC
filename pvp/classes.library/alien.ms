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
			play_sound(ploc(), array('sound': 'ENDERDRAGON_HIT', 'pitch': 2));
			set_pexp(0);
			set_interval(250, closure(){
				try {
					@xp = pexp();
					@xp = min(99, @xp + 10);
					set_pexp(@xp);
					if(@xp == 99) {
						clear_task();
					}
				} catch(Exception @ex) {
					clear_task();
				}
			});
			if(extension_exists('CHSpigot')) {
				@dmg = get_arrow_damage(@arrow);
				set_arrow_damage(@arrow, @dmg * 0.5);
			}
		}
	}

	bind(projectile_hit, array('id': @player.'hit'), array('type': 'ARROW'), @e, @shooter = puuid(@player)) {
		if(@e['shooter'] == @shooter && entity_type(@e['id'])) {
			entity_remove(@e['id']);
		}
	}

	bind(player_interact, array('id': @player.'teleport'), array('item': 381, 'player': @player, 'button': 'right'), @e, @pvp) {
		if(pinfo(player(), 6) != @e['item']) {
			die();
		}
		cancel();
		@players = _hit_scan(player(), 96, 1, 'happy_villager', 'ender_signal', @pvp);

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
			make_effect(_relative(@loc1, 'up', 2), 'ENDER_SIGNAL');
		}

		play_named_sound(ploc(), array('sound': 'entity.elder_guardian.hurt', 'pitch': 2));
		try {
			@item = pinv(player(), null);
			@item['qty'] -= 1;
			if(@item['qty'] == 0) {
				set_pinv(player(), array(null: null));
			} else {
				set_pinv(player(), array(null: @item));
			}
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
