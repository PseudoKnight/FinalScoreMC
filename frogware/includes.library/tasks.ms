proc _fw_task(@task, @state, @secs) {
	switch(@task) {
	case 'climb':
		if(@state == 'start') {
			_fw_msg(array(
				'Climb.',
				'Get on up!',
				'Parkour to the top!',
				'JUMP JUMP JUMP',
			));
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
			if(rand(4)) {
				queue_push(closure(){
					_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
					array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
					'133:0', 3);
				}, 'fw3');
			} else {
				queue_push(closure(){
					_iterate_cuboid(array(@region[0][0], @region[1][1] + 2, @region[0][2], 'custom'),
					array(@region[1][0], @region[1][1] + 2, @region[1][2], 'custom'),
					'57:0', 3);
				}, 'fw3');

				queue_push(closure(){
					_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
					array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
					'133:0', 3);
				}, 'fw3');
			}


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
			_fw_msg(array(
				'Don\'t take damage!',
				'Watch out!',
				'Everything\'s out to get you!',
				'Be safe.',
			));
			if(!rand(4)) {
				_fw_randompotion(array('speed', 'jump', 'blind'))
			}
			_fw_mobs();
			if(!rand(4)) {
				_fw_mobs('random', 25);
			}
			foreach(@p in all_players()) {
				set_ponfire(@p, 0);
			}
			bind(entity_damage, array('id': 'fwtaskdamage'), array('type': 'PLAYER', 'world': 'custom'), @e) {
				if(_fw_player(@e['player'])
				&& (!array_index_exists(@e, 'damager') || !ponline(@e['damager']))) {
					if(_fw_changeteam(@e['player'], 'losers')) {
						play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player']);
					}
				}
			}
			if(rand(2)) {
				bind(target_player, array('id': 'fwtargetplayer'), null, @e) {
					if(rand(2)) {
						@leader = _fw_leader();
						if(@leader && _fw_player(@e['player']) && @e['player'] != @leader) {
							modify_event('player', @leader);
						}
					}
				}
			}
			_fw_set_winners();

		} else {
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
				}
			}
			_remove_region_entities('frogware')
			unbind('fwtaskdamage');
			unbind('fwtargetplayer');
			_fw_startround(@secs)

		}

	case 'harvest':
		if(@state == 'start') {
			_fw_msg(array(
				'Bring in the harvest!',
				'The farm life\'s for you.',
				'Bring life from the bones of the fallen!',
				'Get what? Get wheat!',
				'Plant seeds. Bonemeal them. Get wheat.',
			));
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
					modify_event('item', null);
					play_sound(ploc(), array('sound': 'zombie_metal'), player());
				}
			}

		} else {
			unbind('fwpickup')
			_remove_region_entities('frogware', array('DROPPED_ITEM'));
			_fw_startround(@secs);

		}

	case 'koth':
		if(@state == 'start') {
			_fw_msg(array(
				'King of the Hill',
				'Be the Emerald King, Lord Frog Hill',
				'This hill\'s only big enough for one of you!',
				'The others are disrespecting your hill. Fight!',
			))
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
			@loc = _fw_loc();
			if(rand(4)) {
				# platform
				_iterate_cuboid(array(@loc[0] + 2, @loc[1], @loc[2] + 2, 'custom'),
				array(@loc[0] - 2, @loc[1], @loc[2] - 2, 'custom'),
				'155:0', 100);
				_iterate_cuboid(array(@loc[0] + 1, @loc[1] + 1, @loc[2] + 1, 'custom'),
				array(@loc[0] - 1, @loc[1] + 1, @loc[2] - 1, 'custom'),
				'133:0', 100);
			} else {
				# pillar (king of the ladder)
				_iterate_cuboid(array(@loc[0], @loc[1], @loc[2], 'custom'),
				array(@loc[0], @loc[1] + 5, @loc[2], 'custom'),
				'133:0', 100);
				_iterate_cuboid(array(@loc[0], @loc[1], @loc[2] + 1, 'custom'),
				array(@loc[0], @loc[1] + 5, @loc[2] + 1, 'custom'),
				'65:3', 100);
				_iterate_cuboid(array(@loc[0] - 1, @loc[1], @loc[2], 'custom'),
				array(@loc[0] - 1, @loc[1] + 5, @loc[2], 'custom'),
				'65:4', 100);
				_iterate_cuboid(array(@loc[0], @loc[1], @loc[2] - 1, 'custom'),
				array(@loc[0], @loc[1] + 5, @loc[2] - 1, 'custom'),
				'65:0', 100);
				_iterate_cuboid(array(@loc[0] + 1, @loc[1], @loc[2], 'custom'),
				array(@loc[0] + 1, @loc[1] + 5, @loc[2], 'custom'),
				'65:5', 100);
			}

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
			_fw_msg(array(
				'Let there be cake!',
				'Tea party!',
				'And now for the gluttony round.',
				'I hope you like cake!',
			));
			if(!rand(4)) {
				_fw_randompotion(array('speed'))
			}
			if(rand(4)) {
				for(@i = 0, @i < max(1, floor(_fw_totalplayers() / 2)), @i++) {
					set_block_at(_fw_loc(), '92:0');
				}
			} else {
				for(@i = 0, @i <= _fw_totalplayers(), @i++) {
					set_block_at(_fw_loc(), '92:4')
				}
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
			_fw_msg(array(
				'Alls well that falls well.',
				'What goes up, must come down.',
				'Stay on target!',
			));
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					set_pvelocity(@p, rand(), 3, rand())
					play_sound(ploc(@p), array('sound': 'ghast_fireball'), @p)
				}
			}
			@region = sk_region_info('frogware', 'custom')[0]
			queue_delay(600, 'fw3')
			if(rand(2)) {
				queue_push(closure(){
					_iterate_cuboid(array(@region[0][0], @region[1][1] + 3, @region[0][2], 'custom'),
					array(@region[1][0], @region[1][1] + 3, @region[1][2], 'custom'),
					'133:0', 3);
				}, 'fw3');
			} else {
				_fw_set_winners();
				queue_push(closure(){
					_iterate_cuboid(array(@region[0][0] - 1, @region[1][1] - 1, @region[0][2] - 1, 'custom'),
					array(@region[1][0] + 1, @region[1][1] - 1, @region[1][2] + 1, 'custom'),
					'8:0', 3);
				}, 'fw3');
				bind(entity_damage, array('id': 'fwfall'), array('type': 'PLAYER', 'cause': 'FALL'), @e) {
					if(_fw_player(@e['player'])) {
						if(_fw_changeteam(@e['player'], 'losers')) {
							play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player']);
						}
					}
				}
			}

		} else {
			if(has_bind('fwfall')){
				unbind('fwfall');
				foreach(@p in all_players('custom')) {
					if(_fw_player(@p) && !array_contains(sk_current_regions(@p), 'frogware')) {
						set_ploc(@p, _relative(ploc(@p), 'up'));
					}
				}
			} else {
				foreach(@p in all_players('custom')) {
					if(_fw_player(@p)
					&& get_block_at(ploc(@p)) === '133:0'
					&& _fw_changeteam(@p, 'winners')) {
						play_sound(ploc(@p), array('sound': 'zombie_metal'), @p)
					}
				}
			}
			_fw_startround(@secs);

		}

	case 'cluck':
		if(@state == 'start') {
			if(!rand(4), @mob = 'BAT', @mob = 'CHICKEN')
			@count = if(@mob === 'BAT', '1', '3');
			_fw_msg(array(
				'Shoot '.@count.'!',
				'KILL ALL '.@mob.'S! Well, '.@count.' of them.',
			));
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
						set_pexp(@e['cause']['shooter'], min(99, pexp(@e['cause']['shooter']) + 33))
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
			_fw_msg(array(
				'Pop the frog egg!',
				'That ain\'t no dragon egg!',
				'That\'s no obsidian! It\'s a thing to right-click!',
				'Let\'s make an omellete.',
			))
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
			_fw_msg(array(
				'Last hit gets you a point.',
				'Hit others, but don\'t get hit yourself.',
				'PVP round!',
				'It\'s a free-for-all!',
			));
			_fw_randompotion(array('speed', 'jump', 'blind', 'invis'))
			@weapon = '267:226'; # iron sword
			switch(rand(3)) {
				case 0:
					@weapon = '261:379'; # bow
				case 1:
					@weapon = '332:0';
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
			bind(entity_damage, array('id': 'fwdamage2'), array('type': 'PLAYER', 'world': 'custom'), @e, @weapon) {
				if(array_index_exists(@e, 'damager') && _fw_player(@e['player'])) {
					@damager = @e['damager'];
					if(array_index_exists(@e, 'shooter')) {
						@damager = @e['shooter'];
					}
					if(_fw_player(@damager) && (@weapon == '267:226' || array_index_exists(@e, 'shooter'))) {
						if(_fw_changeteam(@damager, 'winners')) {
							play_sound(ploc(), array('sound': 'zombie_metal'), player())
						}
						if(_fw_changeteam(@e['player'], 'losers')) {
							play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player']);
						}
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
			_fw_msg(array(
				'The lava is lava',
				'Do you smell something burning?',
				'Frogs don\'t like lava. Just sayin\'.',
			))
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
					if(_fw_changeteam(@e['player'], 'losers')) {
						play_sound(ploc(@e['player']), array('sound': 'zombie_unfect'), @e['player']);
					}
				}
			}
			_fw_set_winners();

		} else {
			_remove_region_entities('frogware')
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					_clear_peffects(@p)
				}
			}
			unbind('fwdamage2');
			_fw_startround(@secs);
		}

	case 'shepherd':
		if(@state == 'start') {
			@colors = array('WHITE', 'ORANGE', 'MAGENTA', 'LIGHT_BLUE', 'YELLOW', 'LIME', 'PINK', 'GRAY', 'SILVER', 'CYAN', 'PURPLE', 'BLUE', 'BROWN', 'GREEN', 'RED', 'BLACK')
			@colorindex = rand(array_size(@colors))
			@color = @colors[@colorindex];
			_fw_msg(array(
				@color.color('r').' is the new black',
				'Shear the '.@color.color('r').' ones!',
				'I could use a new '.@color.color('r').' wool coat.',
				'Farmer bob needs your help. Get the '.@color.color('r').' wool.',
			));
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
							play_sound(ploc(), array('sound': 'zombie_metal'), player());
						}
					} else {
						modify_event('item', null);
						play_sound(ploc(), array('sound': 'villager_no'), player());
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
			_fw_msg(array(
				'Alls not well... ALLS NOT WELL!',
				'When it rains, it pours.',
				'ACME delivery!',
				'Etho\'s gonna getcha!',
				'It\'s a bird! It\'s a plane! No! It\'s ** SPLAT **',
			))
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
			_fw_msg(array(
				'Make a trade.',
				'Haggle.',
				'Barter.',
			));
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
			_fw_msg(array(
				'Catch a thing!',
				'Reel it in!',
				'Catch a frog or a pig... Either.',
			));
			foreach(@p in all_players('custom')) {
				if(_fw_player(@p)) {
					pgive_item(@p, '346:60', 1);
				}
			}
			_fw_mobs('speedypig', 1);
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
