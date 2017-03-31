proc _open_objective_menu() {
	@objectives = array('treasurehunt', 'elimination');
	@menu = array(
		'id': 'shard',
		'type': 'HOPPER',
		'title': 'Choose an Objective',
		'0': array(
			'name': 'IRON_SWORD', 'meta': array(
				'display': color('aqua').'ELIMINATION',
				'flags': array('HIDE_ATTRIBUTES'),
				'lore': array(
					color('white').'Eliminate all other players not in your team.',
			))
		),
		'1': array(
			'name': 'ENDER_CHEST', 'meta': array(
				'display': color('aqua').'TREASUREHUNT',
				'lore': array(
					color('white').'Collect randomly buried treasure. Players respawn.',
					color('white').'One minute after a treasure is found and retrieved,',
					color('white').'another is spawned. Compasses point to treasures,',
					color('white').'but coordinates are also given.',
			))
		),
	);
	create_virtualchest(@menu);
	popen_virtualchest('shard');
	
	bind(inventory_click, array('id': player().'click'), array('player': player()), @event, @objectives) {
		if(is_null(pget_virtualchest())) {
			cancel();
			close_pinv();
			die();
		}
		@item = @event['slotitem'];
		if(@item && @item['meta'] && @item['meta']['display']) {
			@objective = to_lower(substr(@item['meta']['display'], 2));
			if(array_contains(@objectives, @objective)) {
				unbind();
				unbind(player().'open');
				_open_rules_menu(@objective);
			}
		}
	}
	
	bind(inventory_close, array('id': player().'open'), null, @event, @player = player()) {
		if(player() == @player) {
			unbind();
			unbind(player().'click');
			del_virtualchest('shard');
		}
	}
}

proc _open_rules_menu(@objective) {
	@activated = array('name': 'INK_SACK', 'data': 10, 'meta': array('display': color('green').'ACTIVATED'));
	@deactivated = array('name': 'INK_SACK', 'data': 8, 'meta': array('display': color('gray').'DEACTIVATED'));
	@options = array(
		'loot': array(
			'default': true,
			'shown': true,
			'item': array(
				'name': 'CHEST', 'meta': array(
					'display': color('aqua').color('bold').'RANDOM LOOT',
					'lore': array(
						color('white').'Existing chests have randomized loot in them.',
						color('yellow').'RANDOM, BUT FAIR!'
			)))
		),
		'keep': array(
			'default': false,
			'shown': true,
			'item': array(
				'name': 'DIAMOND_CHESTPLATE', 'meta': array(
					'display': color('aqua').color('bold').'KEEP INVENTORY',
					'flags': array('HIDE_ATTRIBUTES'),
					'lore': array(
						color('white').'Players keep their current inventory.',
						color('red').'VERY UNFAIR!'
			)))
		),
		'megadestruction': array(
			'default': false,
			'shown': true,
			'item': array(
				'name': 'TNT', 'meta': array(
					'display': color('aqua').color('bold').'MEGA DESTRUCTION',
					'lore': array(
						color('white').'Who needs tools when you have',
						color('white').'instant TNT and Fireballs.',
			)))
		),
		'noregen': array(
			'default': false,
			'shown': true,
			'item': array(
				'name': 'GOLDEN_APPLE', 'meta': array(
					'display': color('aqua').color('bold').'DISABLE HEALTH REGEN',
					'lore': array(
						color('white').'Disables health regeneration from hunger satiation.',
						color('white').'Potions and golden apples still regenerate health.',
						color('gold').'HARD, BUT FAIR!'
			)))
		),
		'randomspawn': array(
			'default': false,
			'shown': true,
			'item': array(
				'name': 'MELON_SEEDS', 'meta': array(
					'display': color('aqua').color('bold').'ALL RANDOM SPAWNS',
					'lore': array(
						color('white').'Selects a random spawn for all players,',
						color('white').'even if they\'re within the region.',
						color('yellow').'RANDOM, BUT FAIR-ISH!'
			)))
		),
		'teams': array(
			'default': 0,
			'shown': true,
			'values': array(0, 2, 3, 4),
			'item': array(
				'name': 'SKULL_ITEM', 'data': 3, 'meta': array(
					'display': color('aqua').color('bold').'TEAMS',
					'lore': array(
						color('white').'Number of teams'
			)))
		),
		'width': array(
			'default': 1024,
			'shown': true,
			'values': array(256, 384, 512, 768, 1024),
			'item': array(
				'name': 'END_CRYSTAL', 'meta': array(
					'display': color('aqua').color('bold').'WORLDBORDER WIDTH',
					'lore': array(
						color('white').'Width of shard world border'
			)))
		),
		'timelimit': array(
			'objective': 'elimination',
			'default': 20,
			'shown': true,
			'values': array(0, 10, 15, 20, 25, 30, 45, 60),
			'item': array(
				'name': 'WATCH', 'meta': array(
					'display': color('aqua').color('bold').'TIME LIMIT',
					'lore': array(
						color('white').'How much time for the worldborder to collapse',
						color('white').'If deactivated, the worldborder will not collapse',
						color('white').'and it will override BUFFER TIME'
			)))
		),
		'buffertime': array(
			'default': 0,
			'shown': true,
			'values': array(0, 1, 3, 5, 10, 15, 20),
			'item': array(
				'name': 'WATCH', 'meta': array(
					'display': color('aqua').color('bold').'BUFFER TIME',
					'enchants': array(array('etype': 'DURABILITY', 'elevel': 1)),
					'flags': array('HIDE_ENCHANTS'),
					'lore': if(@objective == 'elimination',
						array(
							color('white').'How much time before the worldborder collapses.',
							color('white').'If deactivated, the worldborder will collapse after first death.'
						),
						array(
							color('white').'How much time before the first treasure is spawned.',
						),
					),
			))
		),
		'treasures': array(
			'objective': 'treasurehunt',
			'default': 3,
			'shown': true,
			'values': array(3, 5, 7, 10),
			'item': array(
				'name': 'ENDER_CHEST', 'meta': array(
					'display': color('aqua').color('bold').'NUMBER OF TREASURES',
					'lore': array(
						color('white').'How many treasures a player or team must',
						color('white').'find to win the shard.',
			)))
		),
	);
	@menu = array(
		'id': 'shard',
		'size': 45,
		'title': 'Rules',
		44: array(
			'name': 'DIAMOND_SWORD', 'meta': array(
				'display': color('green').color('bold').'ENTER SHARD',
				'enchants': array(array('elevel': 1, 'etype': 'DURABILITY')),
				'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES')
			)
		),
	)
	
	// Populate rules and menu with provided options
	@index = 0;
	@rules = array();
	foreach(@name: @option in @options) {
		if(array_index_exists(@option, 'objective') && @option['objective'] != @objective) {
			continue();
		}
		if(@option['default']) {
			if(is_integral(@option['default'])) {
				if(@option['default'] > 127) {
					@menu[@index] = @activated[];
					@menu[@index]['meta']['display'] = color('green').@option['default'];
					@menu[@index]['qty'] = array_index(@option['values'], @option['default']);
				} else {
					@menu[@index] = @activated[];
					@menu[@index]['qty'] = @option['default'];
				}
			} else {
				@menu[@index] = @activated;
			}
		} else {
			@menu[@index] = @deactivated;
		}
		@menu[@index + 9] = @option['item'];
		@rules[] = array('name': @name, 'value': @option['default']);
		@index++;
		if(@index % 9 == 0) {
			@index += 9;
		}
	}
	@rules[] = array('name': 'objective', 'value': @objective);
	create_virtualchest(@menu);
	popen_virtualchest('shard');
	
	bind(inventory_click, array('id': player().'click'), array('player': player()), @event, @rules, @options) {
		if(is_null(pget_virtualchest())) {
			cancel();
			close_pinv();
			die();
		}
		@item = @event['slotitem'];
		if(!@item) {
			die();
		}
		cancel();
		@slot = @event['slot'];
		if(@slot == 44) {
			close_pinv();
			include('game.ms');
			@associative_rules = associative_array();
			foreach(@rule in @rules) {
				@associative_rules[@rule['name']] = @rule['value'];
			}
			_shard_create(@associative_rules);
		} else {
			@rule = null;
			if(@item['name'] == 'INK_SACK') {
				@rule = array_get(@rules, @slot, null);
			} else {
				@slot -= 9;
				@item = @event['inventory'][@slot];
				@rule = array_get(@rules, @slot, null);
			}
			if(@rule) {
				if(is_boolean(@rule['value'])) {
					if(@rule['value']) {
						@item['data'] = 8;
						@item['meta']['display'] = color('gray').'DEACTIVATED';
						@rule['value'] = false;
					} else {
						@item['data'] = 10;
						@item['meta']['display'] = color('green').'ACTIVATED';
						@rule['value'] = true;
					}
				} else if(is_integer(@rule['value'])) {
					@values = @options[@rule['name']]['values'];
					@index = array_index(@values, @rule['value']);
					@index++;
					if(@index == array_size(@values)) {
						@rule['value'] = @values[0];
						@index = 0;
					} else {
						@rule['value'] = @values[@index];
					}
					if(@rule['value']) {
						if(@rule['value'] > 127) {
							@item['meta']['display'] = color('green').@rule['value'];
							@item['qty'] = @index + 1;
						} else {
							@item['meta']['display'] = color('green').'ACTIVATED';
							@item['qty'] = @rule['value'];
						}
						@item['data'] = 10;
					} else {
						@item['qty'] = 1;
						@item['data'] = 8;
						@item['meta']['display'] = color('gray').'DEACTIVATED';
					}
				}
				@inv = array();
				@inv[@slot] = @item;
				update_virtualchest('shard', @inv);
			}
		}
	}
	
	bind(inventory_close, array('id': player().'open'), null, @event, @player = player()) {
		if(player() == @player) {
			unbind();
			unbind(player().'click');
			del_virtualchest('shard');
		}
	}
}
