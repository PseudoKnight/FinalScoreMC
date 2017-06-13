switch(@action) {
case 'load':
	set_pflight(@player, true);
	bind(player_toggle_flight, array('id': @player.'doublejump'), array('flying': true, 'player': @player), @e) {
		cancel();
		@vel = entity_velocity(puuid());
		set_pvelocity(@vel['x'] * 1.9, 0.9, @vel['z'] * 1.9);
		play_effect(_relative(ploc(), 'up'), 'cloud', array('speed': 0, 'particleCount': 5, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0));
		set_pflight(false);
		queue_delay(2000, player().'doublejump');
		queue_push(closure(){
			set_pflight(true);
		}, player().'doublejump');
	}

	@armor = array(
		100: @pvp['arena']['classes'][@class]['kit'][100],
		101: @pvp['arena']['classes'][@class]['kit'][101],
		102: @pvp['arena']['classes'][@class]['kit'][102],
		103: @pvp['arena']['classes'][@class]['kit'][103],
	);
	bind(player_toggle_sneak, array('id': @player.'ninja'), array('player': @player), @e, @gear = @armor) {
		if(@e['sneaking']) {
			if(entity_grounded(puuid())) {
				set_pinv(array(
					100: null,
					101: null,
					102: null,
					103: null,
				));
				set_peffect(player(), 16, 0, 25);
				set_peffect(player(), 14, 0, 20);
				play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2));
			} else {
				if(has_bind(player().'falldamage')) {
					die();
				}
				bind(entity_damage, array('id': player().'falldamage'), array('cause': 'FALL', 'id': puuid()), @e, @player = player()) {
					if(pinfo(@player, 11)) {
						cancel(); # is sneaking
						@facing = pfacing(@player);
						@facing[0] = @facing[0] + 90;
						@facing[1] = 0 - @facing[1];
						@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
						@y = 0;
						@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
						set_pvelocity(@player, @x, @y, @z);
						play_named_sound(ploc(@player), array('sound': 'item.armor.equip_leather'));
						set_pinv(@player, array(0: null));
						set_timeout(100, closure(){
							@facing = pfacing(@player);
							@facing[0] = @facing[0] + 90;
							@facing[1] = 0 - @facing[1];
							@x = cos(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
							@y = 0;
							@z = sin(to_radians(@facing[0])) * cos(to_radians(@facing[1]));
							set_pvelocity(@player, @x, @y, @z);
							set_timeout(100, closure(){
								set_pinv(@player, array(0: array('name': 'STONE_SWORD')));
							});
						});
						unbind();
					}
				}
				set_timeout(250, closure(){
					unbind(player().'falldamage');
				});
			}
		} else if(!pinv(player(), 100)){
			set_pinv(@gear);
			set_peffect(player(), 14, 0, 0);
			set_peffect(player(), 16, 0, 0);
			play_effect(_relative(ploc(), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2));
		}
	}

case 'equip':
	@armor = array(
		100: @pvp['arena']['classes'][@class]['kit'][100],
		101: @pvp['arena']['classes'][@class]['kit'][101],
		102: @pvp['arena']['classes'][@class]['kit'][102],
		103: @pvp['arena']['classes'][@class]['kit'][103],
	)

	proc _cloak(@player, @gear) {
		queue_delay(800, @player.'cloaked')
		queue_push(closure(){
			if(ponline(@player) && pinfo(@player, 5) > 0) {
				if(pinfo(@player, 11) && !pinv(@player, 100)) {
					set_pexp(@player, max(0, pexp(@player) - 3));
					if(pexp(@player) == 0) {
						set_pinv(@player, @gear)
						set_peffect(@player, 14, 0, 0)
						set_peffect(@player, 16, 0, 0)
						play_effect(_relative(ploc(@player), 'up', 2), 'spell', array('speed': 0, 'particleCount': 10, 'offsetY': 0.4, 'offsetX': 0.2, 'offsetZ': 0.2))
					}
				} else {
					set_pexp(@player, min(99, pexp(@player) + 3));
				}
				_cloak(@player, @gear)
			}
		}, @player.'cloaked')
	}
	_cloak(@player, @armor)

case 'unload':
	unbind(@player.'ninja');
	unbind(@player.'doublejump');
	queue_clear(@player.'cloaked');
	queue_clear(@player.'doublejump');

}
