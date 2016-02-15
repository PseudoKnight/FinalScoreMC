proc _fw_task(@task, @state, @secs) {
	switch(@task) {
	case 'climb':
		if(@state == 'start') {
			_fw_msg('Climb.')
			if(!rand(4)) {
				_fw_randompotion(array('speed', 'jump', 'blind'))
			}
			if(!rand(4)) {
				_fw_mobs()
			}
			@region = sk_region_info('frogware', 'custom')[0]
			queue_push(closure(){
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'41:0', 5);
			}, 'fw3');
			queue_delay(500, 'fw3')
			queue_push(closure(){
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 1, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 1, @region[1][2], 'custom'),
				'57:0', 4);
			}, 'fw3');
			queue_delay(500, 'fw3')
			queue_push(closure(){
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'133:0', 3);
			}, 'fw3');

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
					if(get_block_at(ploc(@p)) === '133:0'
					&& _fw_changeteam(@p, 'winners')) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			}
			_remove_region_entities('frogware');
			_fw_startround(@secs);
		}

	case 'keepaway':
		if(@state == 'start') {
			_fw_msg('Look out!')
			if(!rand(4)) {
				_fw_randompotion(array('speed', 'jump', 'blind'))
			}
			_fw_mobs()
			bind(entity_damage, array('id': 'fwtaskdamage'), array('type': 'PLAYER', 'world': 'custom'), @e) {
				if((@e['cause'] === 'ENTITY_ATTACK' || @e['cause'] === 'ENTITY_EXPLOSION')
				&& _fw_player(@e['player'])
				&& !ponline(@e['damager'])) {
					_fw_changeteam(@e['player'], 'losers')
				}
			}
			_fw_set_winners();

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
					if(array_contains(get_teams('fw')[1]['players'], @p)) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			}
			_remove_region_entities('frogware')
			unbind('fwtaskdamage')
			_fw_startround(@secs)

		}

	case 'harvest':
		if(@state == 'start') {
			_fw_msg('Bring in the harvest!')
			_fw_items(array('type': 351, 'data': 15, 'qty': 1), 100);
			@region = sk_region_info('frogware', 'custom')[0]
			_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
			array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
			'3:0', 2);
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					pgive_item(@p, '291:130', 1); # stone hoe
					pgive_item(@p, 295, 1); # seeds
				}
			}
			bind(item_pickup, array('id': 'fwpickup'), array('item': 296), @e) {
				if(_fw_player(player())
				&& _fw_changeteam(player(), 'winners')) {
					play_sound(ploc(), array('sound': 'zombie_metal'), player())
				}
			}

		} else {
			unbind('fwpickup')
			_remove_region_entities('frogware', array('DROPPED_ITEM'));
			_fw_startround(@secs);

		}

	case 'koth':
		if(@state == 'start') {
			_fw_msg('King of the Hill')
			if(!rand(4)) {
				_fw_mobs()
			}
			if(!rand(4)) {
				foreach(@p in all_players('custom')) {
					if(_fw_player(@p)) {
						# knockback mushroom
						pgive_item(@p, 40, 1, array(array('etype': 'KNOCKBACK', 'elevel': 10)))
					}
				}
			}
			if(!rand(4)) {
				@region = sk_region_info('frogware', 'custom')[0];
				_iterate_cuboid(array(@region[0][0], @region[1][1], @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1], @region[1][2], 'custom'),
				'9:0', 100);
				@count = _fw_totalplayers() * 2;
				for(@i = 0, @i < @count, @i++) {
					drop_item(_fw_loc(), array('name': 'IRON_BOOTS', 'enchants': array(
						array('elevel': 3, 'etype': 'DEPTH_STRIDER'),
					)));
				}
			} else if(!rand(4)) {
				_fw_randompotion(array('speed', 'jump'));
			}
			@loc = _fw_loc()
			_iterate_cuboid(array(@loc[0] + 2, @loc[1], @loc[2] + 2, 'custom'),
			array(@loc[0] - 2, @loc[1], @loc[2] - 2, 'custom'),
			'155:0', 100)
			_iterate_cuboid(array(@loc[0] + 1, @loc[1] + 1, @loc[2] + 1, 'custom'),
			array(@loc[0] - 1, @loc[1] + 1, @loc[2] - 1, 'custom'),
			'133:0', 100)

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
					if(get_block_at(ploc(@p)) === '133:0'
					&& _fw_changeteam(@p, 'winners')) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			}
			_remove_region_entities('frogware');
			_fw_startround(@secs);

		}

	case 'cake':
		if(@state == 'start') {
			_fw_msg('Let there be cake!')
			if(!rand(4)) {
				_fw_randompotion(array('speed'))
			}
			for(@i = 0, @i < max(1, floor(_fw_totalplayers() / 2)), @i++) {
				set_block_at(_fw_loc(), '92:0')
			}
			bind(player_interact, array('id': 'fwcake'), array('block': 92), @e) {
				if(_fw_player(player())
				&& _fw_changeteam(player(), 'winners')) {
					play_sound(ploc(), array('sound': 'zombie_metal'), player())
				}
			}

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
				}
			}
			unbind('fwcake')
			_fw_startround(@secs)
		}

	case 'fall':
		if(@state == 'start') {
			_fw_msg('Alls well that falls well.')
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					set_pvelocity(@p, rand(), 3, rand())
					play_sound(ploc(@p), array('sound': 'ghast_fireball'), @p)
				}
			}
			@region = sk_region_info('frogware', 'custom')[0]
			queue_delay(600, 'fw3')
			queue_push(closure(){
				_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
				'133:0', 3);
			}, 'fw3')

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)
				&& get_block_at(ploc(@p)) === '133:0'
				&& _fw_changeteam(@p, 'winners')) {
					play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
				}
			}
			_fw_startround(@secs);

		}

	case 'cluck':
		if(@state == 'start') {
			if(!rand(4), @mob = 'BAT', @mob = 'CHICKEN')
			_fw_msg('Shoot '.if(@mob === 'BAT', '1', '3').'!')
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					pgive_item(@p, '261:379', 1, array(array('elevel': 1, 'etype': 'ARROW_FIRE')));
					pgive_item(@p, 262, 6);
					play_sound(ploc(@p), array('sound': if(@mob === 'BAT', 'BAT_LOOP', 'chicken_idle')), @p)
					set_pexp(@p, 0)
				}
			}

			for(@i = 0, @i < (_fw_totalplayers() * 4), @i++) {
				spawn_mob(@mob, 1, if(@mob === 'BAT', _fw_loc(8), _fw_loc(18)))
			}
			bind(entity_death, array('id': 'fwcluck'), array('type': @mob), @e, @mob) {
				if(array_index_exists(@e['cause'], 'shooter')
				&& ponline(@e['cause']['shooter'])
				&& _fw_player(@e['cause']['shooter'])) {
					modify_event('xp', 0)
					if(@e['type'] === 'BAT') {
						set_pexp(@e['cause']['shooter'], 99)
					} else {
						set_pexp(@e['cause']['shooter'], pexp(@e['cause']['shooter']) + 33)
					}
					if(pexp(@e['cause']['shooter']) > 90
					&& _fw_changeteam(@e['cause']['shooter'], 'winners')) {
						play_sound(ploc(@e['cause']['shooter']), array('sound': 'zombie_metal'), @e['cause']['shooter'])
					}
				}
			}

		} else {
			unbind('fwcluck')
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					set_pexp(@p, 0)
				}
			}
			_fw_startround(@secs)

		}

	case 'frogegg':
		if(@state == 'start') {
			_fw_msg('Pop the frog egg!')
			@loc = _fw_loc()
			set_block_at(@loc, '122:0')
			if(!rand(4)) {
				_fw_mobs()
			}
			if(!rand(4)) {
				@blocks = import('frogware.blocks');
				if(is_null(@blocks)) {
					@blocks = array();
				}
				for(@i = 0, @i < 16, @i++) {
					set_block_at(_fw_loc(), '49:0')
				}
				export('frogware.blocks', @blocks);
			}
			play_sound(@loc, array('sound': 'CHICKEN_EGG_POP', 'volume': 3))
			bind(player_interact, array('id': 'fwegg', 'priority': 'high'), array('block': 122), @e) {
				if(_fw_player(player())) {
					play_sound(@e['location'], array('sound': 'CHICKEN_EGG_POP', 'volume': 3))
					consume()
					if(_fw_changeteam(player(), 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
				}
			}

		} else {
			unbind('fwegg')
			_remove_region_entities('frogware')
			_fw_clear_blocks(1);
			_fw_startround(@secs)

		}

	case 'pvp':
		if(@state == 'start') {
			_fw_msg('Last hit.')
			_fw_randompotion(array('speed', 'jump', 'blind', 'invis'))
			@weapon = '267:226'; # iron sword
			if(!rand(3)) {
				@weapon = '261:379'; # bow
			}
			@meta = null;
			if(!rand(4)) {
				@meta = array(array(
					array('etype': 'KNOCKBACK', 'elevel': 8),
					array('etype': 'PUNCH', 'elevel': 8)
				))
			}
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					pgive_item(@p, @weapon, 1, @meta);
					if(@weapon == '261:379') {
						pgive_item(@p, 262, 10);
					}
				}
			}
			bind(entity_damage, array('id': 'fwdamage2'), array('type': 'PLAYER', 'world': 'custom'), @e) {
				if(array_index_exists(@e, 'damager') && _fw_player(@e['player'])) {
					@damager = @e['damager'];
					if(array_index_exists(@e, 'shooter')) {
						@damager = @e['shooter'];
					}
					if(_fw_player(@damager)) {
						if(_fw_changeteam(@damager, 'winners')) {
							play_sound(ploc(), array('sound': 'zombie_metal'), player())
						}
						_fw_changeteam(@e['player'], 'losers')
						play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player'])
					}
				}
			}

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
				}
			}
			unbind('fwdamage2')
			_fw_startround(@secs)

		}

	case 'lavafall':
		if(@state == 'start') {
			_fw_msg('The lava is lava')
			if(!rand(4)) {
				_fw_randompotion(array('speed', 'blind'))
			}
			if(!rand(4)) {
				_fw_mobs()
			}
			if(!rand(4)) {
				foreach(@p in all_players('custom')) {
					if(_fw_player(@p)) {
						pgive_item(@p, 325, 1); # bucket
					}
				}
			}
			@region = sk_region_info('frogware', 'custom')[0]
			_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
				array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
				'10:0', 3)
			bind(entity_damage, array('id': 'fwdamage2'), array('type': 'PLAYER', 'cause': 'LAVA', 'world': 'custom'), @e) {
				if(_fw_player(@e['player'])) {
					_fw_changeteam(@e['player'], 'losers')
					play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player'])
				}
			}
			_fw_set_winners();

		} else {
			_remove_region_entities('frogware')
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
					if(array_contains(get_teams('fw')[1]['players'], @p)) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			}
			unbind('fwdamage2');
			_fw_startround(@secs);
		}

	case 'shepherd':
		if(@state == 'start') {
			@colors = array('WHITE', 'ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'PINK', 'GRAY', 'SILVER', 'CYAN', 'PURPLE', 'BLUE', 'BROWN', 'GREEN', 'RED', 'BLACK')
			@colorindex = rand(array_size(@colors))
			_fw_msg(@colors[@colorindex].color('r').' is the new black')
			@count = min(_fw_totalplayers() * 24, 200)
			@region = sk_region_info('frogware', 'custom')[0]
			for(@i = 0, @i < @count, @i++) {
				spawn_mob('SHEEP:'.@colors[rand(16)], 1, _fw_loc())
			}
			if(!rand(4)) {
				_fw_mobs('wolf:angry', 8);
			}
			bind(item_pickup, array('id': 'fwpickup'), array('item': 35), @e, @data = @colorindex) {
				if(_fw_player(@e['player'])) {
					if(@e['item']['data'] == @data) {
						if(_fw_changeteam(player(), 'winners')) {
							play_sound(ploc(), array('sound': 'zombie_metal'), player())
						}
					}
				}
			}
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					pgive_item(@p, '359:235', 1) # shears
				}
			}


		} else {
			_remove_region_entities('frogware')
			unbind('fwpickup')
			_fw_startround(@secs)
		}

	case 'anvil':
		if(@state == 'start') {
			_fw_msg('Alls not well... ALLS NOT WELL!')
			if(!rand(4)) {
				_fw_randompotion(array('speed', 'blind'))
			}
			if(!rand(4)) {
				_fw_mobs()
			}
			bind(entity_damage, array('id': 'fwdamage2'), array('type': 'PLAYER', 'cause': 'FALLING_BLOCK', 'world': 'custom'), @e) {
				if(_fw_player(@e['player'])) {
					_fw_changeteam(@e['player'], 'losers')
					play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player'])
				}
			}
			_fw_set_winners();
			@region = sk_region_info('frogware', 'custom')[0]
			for(@i = 0, @i < @secs - 2, @i++) {
				queue_push(closure(){
					_iterate_cuboid(array(@region[0][0], @region[1][1] + 24, @region[0][2], 'custom'),
						array(@region[1][0], @region[1][1] + 24, @region[1][2], 'custom'),
						145, 3);
					foreach(@p in all_players('custom')) {
						if(get_pscoreboard(@p) == 'fw') {
							@loc = ploc(@p);
							@loc['y'] += 25;
							set_block_at(@loc, '145');
						}
					}
				}, 'fw3');
				queue_delay(1000, 'fw3');
			}

		} else {
			unbind('fwdamage2');
			_remove_region_entities('frogware');
			_fw_clear_blocks(1);
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p);
				}
			}
			_fw_startround(@secs);
		}

	case 'trade':
		if(@state == 'start') {
			_fw_msg('Make a trade');
			_fw_mobs('villager');
			for(@i = 0, @i < 100, @i++) {
				drop_item(_fw_loc(), array('name': 'EMERALD', 'qty': 1));
			}
			bind(inventory_click, array('id': 'fwclick'), array('slottype': 'RESULT'), @e) {
				if(_fw_player(@e['player']) && @e['slotitem']) {
					if(_fw_changeteam(player(), 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
				}
			}
			
		} else {
			unbind('fwclick');
			_remove_region_entities('frogware');
			_fw_startround(@secs);
		}

	case 'fish':
		if(@state == 'start') {
			_fw_msg('Catch a thing');
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					pgive_item(@p, '346:60', 1);
				}
			}
			@region = sk_region_info('frogware', 'custom')[0];
			bind(player_fish, array('id': 'fwfish'), array('state': '/(CAUGHT_ENTITY|CAUGHT_FISH)/'), @e) {
				if(_fw_player(@e['player'])) {
					if(_fw_changeteam(player(), 'winners')) {
						play_sound(ploc(), array('sound': 'zombie_metal'), player())
					}
				}
			}

		} else {
			unbind('fwfish');
			_fw_startround(@secs);
		}
	}

}
