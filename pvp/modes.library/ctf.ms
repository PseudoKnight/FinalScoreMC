proc _pvp_flag_spawn(@id, @team, @loc) {
	@pvp = import('pvp'.@id);
	if(!is_array(@loc)) {
		@loc = @pvp['arena']['ctfflag'][@team];
	}
	try {
		if(_horizontal_distance(entity_loc(@pvp['team'][@team]['flag']), @pvp['arena']['ctfflag'][@team]) > 3) {
			@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': 425, 'data': if(@team == 0, '1', '4')), 0)
		}
	} catch(Exception @ex) {
		@pvp['team'][@team]['flag'] = drop_item(@loc, array('type': 425, 'data': if(@team == 0, '1', '4')), 0);
	}
	queue_delay('30000', @id.@team.'flag');
	queue_push(closure(_pvp_flag_spawn(@id, @team)), @id.@team.'flag');
}

proc _flag(@item) {
	if(!is_null(@item) && @item['type'] == 425) {
		if(@item['data'] == 4) {
			return(1);
		} else if(@item['data'] == 1) {
			return(0);
		}
	}
	return(null);
}

_pvp_flag_spawn(@id, 0);
_pvp_flag_spawn(@id, 1);

array_push(@pvp['binds'], @id.'flagpickup')
bind(item_pickup, array('id': @id.'flagpickup'), null, @e, @id) {
	@pvp = import('pvp'.@id)
	if(!array_index_exists(@pvp['players'], player())) {
		die();
	}

	@flag = _flag(@e['item']);
	if(is_null(@flag)) {
		die();
	}

	if(@flag == @pvp['players'][player()]['team']) {
		if(_horizontal_distance(ploc(), @pvp['arena']['ctfflag'][@flag]) > 3) {
			queue_clear(@id.@flag.'flag');
			modify_event('item', null);
			_pvp_flag_spawn(@id, @flag);
			_pvp_msg(@pvp, color('gray').'[PVP] '
				.@pvp['arena']['team'][@flag]['color'].player().color('r').' returned the '
				.@pvp['arena']['team'][@flag]['color'].'flag');
			play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'pitch': 0));
		} else {
			cancel();
			@heldflag = _flag(pinv(player(), 103));
			if(!is_null(@heldflag)) {
				play_sound(@pvp['arena']['ctfflag'][@flag], array('sound': 'ZOMBIE_METAL', 'volume': 3));
				@pvp['team'][@flag]['score']++;
				set_pscore('captures', @pvp['arena']['team'][@flag]['name'], @pvp['team'][@flag]['score'], @id)
				set_pinv(player(), array(103: null));
				_pvp_msg(@pvp, color('gray').'[PVP] '
					.@pvp['arena']['team'][@flag]['color'].player().color('r').' secured the '
					.@pvp['arena']['team'][@heldflag]['color'].'flag'.color('r').'!');
				if(array_index_exists(@pvp['arena'], 'rsoutputscore')) {
					set_block_at(@pvp['arena']['rsoutputscore'][@flag], '76:5');
					set_timeout(1000, closure(){
						set_block_at(@pvp['arena']['rsoutputscore'][@flag], '50:5');
					})
				}
				_pvp_flag_spawn(@id, @heldflag);
				_pvp_check_objectives(@id);
			}
		}
	} else {
		queue_clear(@id.@flag.'flag');
		modify_event('item', null);
		set_pinv(player(), array(103: array('type': 425, 'data': if(@flag, 4, 1))));
		_pvp_msg(@pvp, color('gray').'[PVP] '
			.@pvp['arena']['team'][if(@flag, 0, 1)]['color'].player().color('r').' picked up the '
			.@pvp['arena']['team'][@flag]['color'].'flag');
		play_sound(ploc(), array('sound': 'ENDERDRAGON_WINGS', 'volume': 3));
	}
}

array_push(@pvp['binds'], @id.'protectdrops')
bind(entity_damage, array('id': @id.'protectdrops'), array('type': 'DROPPED_ITEM'),
@e, @region = @pvp['arena']['region']) {
	if(array_contains(sk_regions_at(entity_loc(@e['id'])), @region)) {
		cancel()
	}
}

if(!array_contains(@pvp['arena']['flags'], 'noinventory')) {
	array_push(@pvp['binds'], @id.'flagclick')
	bind(inventory_click, array('id': @id.'flagclick'), array('slottype': 'ARMOR'), @e, @id) {
		@pvp = import('pvp'.@id)
		if(!array_index_exists(@pvp['players'], player()), die())

		if(!is_null(_flag(@e['slotitem']))) {
			cancel();
		}
	}
}
