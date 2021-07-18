proc _open_objective_menu() {
	@objectives = array('treasurehunt', 'elimination', 'scavengerhunt', 'creative');
	@menu = array(
		'0': array(
			'name': 'IRON_SWORD', 'meta': array(
				'display': color('aqua').'Elimination',
				'flags': array('HIDE_ATTRIBUTES'),
				'lore': array(
					color('white').'Eliminate all other players not in your team.',
			))
		),
		'1': array(
			'name': 'ENDER_CHEST', 'meta': array(
				'display': color('aqua').'Treasure Hunt',
				'lore': array(
					color('white').'Collect randomly buried treasure. Players respawn.',
					color('white').'One minute after a treasure is found and retrieved,',
					color('white').'another is spawned. Compasses point to treasures,',
					color('white').'but coordinates are also given.',
			))
		),
		'2': array(
			'name': 'MAP', 'meta': array(
				'display': color('aqua').'Scavenger Hunt',
				'lore': array(
					color('white').'Find and collect items to complete your card.',
					color('white').'Can be played like BINGO where',
					color('white').'across, down, or diagonal wins the game.',
			))
		),
		'3': array(
			'name': 'GRASS_BLOCK', 'meta': array(
				'display': color('aqua').'Creative',
				'lore': array(
					color('white').'Creative mode in shard.',
					color('white').'Ends when all players exit the world.',
			))
		)
	);
	create_virtual_inventory('shard', 'HOPPER', 'Choose an Objective', @menu);
	popen_inventory('shard');
	play_sound(ploc(), array(sound: 'BLOCK_AMETHYST_BLOCK_CHIME'));

	bind('inventory_click', array('id': player().'click'), array('player': player(), 'virtual': true), @event, @objectives) {
		@item = @event['slotitem'];
		if(@item && @item['meta'] && @item['meta']['display'] && length(@item['meta']['display']) >= 2) {
			@objective = replace(to_lower(substr(@item['meta']['display'], 2)), ' ', '');
			if(array_contains(@objectives, @objective)) {
				unbind();
				unbind(player().'close');
				_open_rules_menu(@objective);
			}
		}
	}

	bind('inventory_close', array('id': player().'close'), null, @event, @player = player()) {
		if(player() == @player) {
			unbind();
			unbind(player().'click');
			delete_virtual_inventory('shard');
		}
	}
}

proc _open_rules_menu(@objective) {
	@activated = array('name': 'LIME_DYE', 'meta': array('display': color('green').'ACTIVATED'));
	@deactivated = array('name': 'GRAY_DYE', 'meta': array('display': color('gray').'DEACTIVATED'));
	@options = array(
		'loot': array(
			'objective': array('elimination', 'treasurehunt'),
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
			'objective': array('elimination', 'treasurehunt', 'creative'),
			'default': false,
			'shown': true,
			'item': array(
				'name': 'DIAMOND_CHESTPLATE', 'meta': array(
					'display': color('aqua').color('bold').'KEEP INVENTORY',
					'flags': array('HIDE_ATTRIBUTES'),
					'lore': array(
						color('white').'Players keep their current inventory.',
						color('red').'VERY UNFAIR!'
			))),
			'show': 'mirrored',
		),
		'mirrored': array(
			'objective': array('elimination', 'treasurehunt'),
			'default': false,
			'shown': true,
			'item': array(
				'name': 'GLASS_PANE', 'meta': array(
					'display': color('aqua').color('bold').'MIRRORED INVENTORY',
					'flags': array('HIDE_ATTRIBUTES'),
					'lore': array(
						color('white').'All players start with the same inventory.',
						color('white').'The shard creator\'s inventory is used.',
						color('white').'Overrides KEEP INVENTORY.',
						color('green').'VERY FAIR!'
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
			'objective': array('elimination'),
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
			'objective': array('elimination', 'treasurehunt', 'scavengerhunt'),
			'default': true,
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
			'objective': array('elimination', 'treasurehunt'),
			'default': 0,
			'shown': true,
			'values': array(0, 2, 3, 4),
			'item': array(
				'name': 'PLAYER_HEAD', 'meta': array(
					'display': color('aqua').color('bold').'TEAMS',
					'lore': array(
						color('white').'Number of teams'
			)))
		),
		'width': array(
			'default': 64,
			'shown': true,
			'values': array(16, 24, 32, 48, 64),
			'item': array(
				'name': 'END_CRYSTAL', 'meta': array(
					'display': color('aqua').color('bold').'WORLDBORDER CHUNK WIDTH',
					'lore': array(
						color('white').'Width of shard world border in chunks',
						color('white').'Max (64) is equal to 1024 meters wide',
			))),
			'result': iclosure(@value) {
				return(@value * 16);
			}
		),
		'timelimit': array(
			'objective': array('elimination'),
			'default': 10,
			'shown': true,
			'values': array(0, 10, 15, 20, 25, 30, 45, 60),
			'item': array(
				'name': 'CLOCK', 'meta': array(
					'display': color('aqua').color('bold').'TIME LIMIT',
					'lore': array(
						color('white').'How much time for the worldborder to collapse',
						color('white').'If deactivated, the worldborder will not collapse',
						color('white').'and it will override BUFFER TIME'
			)))
		),
		'buffertime': array(
			'objective': array('elimination', 'treasurehunt'),
			'default': 0,
			'shown': true,
			'values': array(0, 1, 3, 5, 10, 15, 20),
			'item': array(
				'name': 'CLOCK', 'meta': array(
					'display': color('aqua').color('bold').'BUFFER TIME',
					'enchants': array('unbreaking': 1),
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
			)),
			result: iclosure(@value) {
				return(@value * 60000);
			}
		),
		'cardsize': array(
			'objective': array('scavengerhunt'),
			'default': 5,
			'shown': true,
			'values': array(0, 3, 4, 5, 6),
			'item': array(
				'name': 'DAYLIGHT_DETECTOR', 'meta': array(
					'display': color('aqua').color('bold').'CARD SIZE',
					'lore': array(
						color('white').'The height and width of the card.',
						color('white').'If disabled, uses a full card,',
						color('white').'and requires 4 in a row. In this mode,',
						color('white').'only one player may get each item.',
			)))
		),
	);
	@menu = array(
		44: array(
			'name': 'DIAMOND_SWORD', 'meta': array(
				'display': color('green').color('bold').'ENTER SHARD',
				'enchants': array('unbreaking': 1),
				'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES')
			)
		),
	)

	// Populate rules and menu with provided options
	@index = 0;
	@rules = array();
	foreach(@name: @option in @options) {
		if(array_index_exists(@option, 'objective') && !array_contains(@option['objective'], @objective)) {
			continue();
		}
		if(@option['shown']) {
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
		}
		@rules[] = array('name': @name, 'value': @option['default'], 'slot': @index + 9);
		@index++;
		if(@index % 9 == 0) {
			@index += 9;
		}
	}
	@rules[] = array('name': 'objective', 'value': @objective);
	delete_virtual_inventory('shard');
	create_virtual_inventory('shard', 45, 'Rules', @menu);
	popen_inventory('shard');
	play_sound(ploc(), array(sound: 'BLOCK_AMETHYST_BLOCK_HIT'));

	bind('inventory_click', array('id': player().'click'), array('player': player(), 'virtual': true), @event, @rules, @options) {
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
				@key = @rule['name'];
				if(@key != 'objective' && array_index_exists(@options[@key], 'result')) {
					@associative_rules[@key] = execute(@rule['value'], @options[@key]['result']);
				} else {
					@associative_rules[@key] = @rule['value'];
				}
			}
			play_sound(ploc(), array(sound: 'BLOCK_AMETHYST_BLOCK_HIT'));
			_shard_create(@associative_rules);
		} else {
			if(!string_ends_with(@item['name'], '_DYE')) {
				@slot -= 9;
				if(@slot < 0) {
					die();
				}
			}
			@ruleSlot = @slot - floor(@slot / 9) * 9;
			@item = @event['inventory'][@slot];
			@rule = array_get(@rules, @ruleSlot, null);
			if(@rule) {
				@name = @rule['name'];
				@option = @options[@name];
				if(is_boolean(@rule['value'])) {
					if(@rule['value']) {
						@item['name'] = 'GRAY_DYE';
						@item['meta']['display'] = color('gray').'DEACTIVATED';
						@rule['value'] = false;
					} else {
						@item['name'] = 'LIME_DYE';
						@item['meta']['display'] = color('green').'ACTIVATED';
						@rule['value'] = true;
					}
				} else if(is_integer(@rule['value'])) {
					@values = @option['values'];
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
						@item['name'] = 'LIME_DYE';
					} else {
						@item['qty'] = 1;
						@item['name'] = 'GRAY_DYE';
						@item['meta']['display'] = color('gray').'DEACTIVATED';
					}
				}
				set_inventory_item('shard', @slot, @item);
			}
		}
	}

	bind('inventory_close', array('id': player().'open'), null, @event, @player = player()) {
		if(player() == @player) {
			unbind();
			unbind(player().'click');
			delete_virtual_inventory('shard');
		}
	}
}
