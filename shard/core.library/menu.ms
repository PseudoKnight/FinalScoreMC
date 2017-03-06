proc _create_menu() {
	if(array_contains(all_virtualchests(), 'shard')) {
		action_msg('Another player is generating a shard.');
		die();
	}
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
				'name': 'STEP', 'data': 9, 'meta': array(
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
			'values': array(0, 256, 384, 512, 768, 1024),
			'item': array(
				'name': 'END_CRYSTAL', 'meta': array(
					'display': color('aqua').color('bold').'WORLDBORDER WIDTH',
					'lore': array(
						color('white').'Width of shard world border'
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
		if(!@option['shown']) {
			continue();
		}
		if(@option['default']) {
			@menu[@index] = @activated;
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
				@rule = @rules[@slot];
			} else {
				@slot -= 9;
				@item = @event['inventory'][@slot];
				@rule = @rules[@slot];
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
					} else {
						@rule['value'] = @values[@index];
					}
					if(@rule['value']) {
						if(@rule['value'] > 127) {
							@item['meta']['display'] = color('green').@rule['value'];
							@item['qty'] = @index;
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
