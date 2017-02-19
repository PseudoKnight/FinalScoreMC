proc _create_menu() {
	if(array_contains(all_virtualchests(), 'shard')) {
		action_msg('Another player is generating a shard.');
		die();
	}
	@rules = associative_array(
		array('name': 'loot', 'value': true),
		array('name': 'keep', 'value': false),
		array('name': 'regen', 'value': false),
		array('name': 'randomspawn', 'value': false),
		array('name': 'teams', 'value': 0, 'min': 2, 'max': 4),
	);
	@activated = array('name': 'INK_SACK', 'data': 10, 'meta': array('display': color('green').'ACTIVATED'));
	@deactivated = array('name': 'INK_SACK', 'data': 8, 'meta': array('display': color('gray').'DEACTIVATED'));
	create_virtualchest(array(
		'id': 'shard',
		'size': 27,
		'title': 'Rules',
		0: @activated,
		1: @deactivated,
		2: @deactivated,
		3: @deactivated,
		4: @deactivated,
		9: array(
			'name': 'CHEST', 'meta': array(
				'display': color('aqua').color('bold').'RANDOM LOOT',
				'lore': array(color('white').'Existing chests have randomized loot in them.', color('yellow').'RANDOM, BUT FAIR!'),
			)
		),
		10: array(
			'name': 'DIAMOND_CHESTPLATE', 'meta': array(
				'display': color('aqua').color('bold').'KEEP INVENTORY',
				'lore': array(color('white').'Players keep their current inventory.', color('red').'VERY UNFAIR!'),
				'flags': array('HIDE_ATTRIBUTES')
			)
		),
		11: array(
			'name': 'GOLDEN_APPLE', 'meta': array(
				'display': color('aqua').color('bold').'DISABLE HEALTH REGEN',
				'lore': array(
					color('white').'Disables health regeneration from hunger satiation.',
					color('white').'Potions and golden apples still regenerate health.',
					color('gold').'HARD, BUT FAIR!'
				),
			)
		),
		12: array(
			'name': 'STEP', 'data': 9, 'meta': array(
				'display': color('aqua').color('bold').'ALL RANDOM SPAWNS',
				'lore': array(
					color('white').'Selects a random spawn for all players,',
					color('white').'even if they\'re within the region.',
					color('yellow').'RANDOM, BUT FAIR-ISH!'
				),
			)
		),
		13: array(
			'name': 'SKULL_ITEM', 'data': 3, 'meta': array(
				'display': color('aqua').color('bold').'TEAMS',
				'lore': array(
					color('white').'Number of teams'
				),
			)
		),
		26: array(
			'name': 'DIAMOND_SWORD', 'meta': array(
				'display': color('green').color('bold').'ENTER SHARD',
				'enchants': array(array('elevel': 1, 'etype': 'DURABILITY')),
				'flags': array('HIDE_ENCHANTS', 'HIDE_ATTRIBUTES')
			)
		),
	));
	popen_virtualchest('shard');
	
	bind(inventory_click, array('id': player().'click'), array('player': player()), @event, @rules) {
		if(is_null(pget_virtualchest())) {
			cancel();
			close_pinv();
			die();
		}
		cancel();
		@slot = @event['slot'];
		if(@slot == 26) {
			close_pinv();
			include('game.ms');
			_shard_create(@rules);
		} else {
			@item = @event['slotitem'];
			@rule = null;
			if(array_index_exists(@rules, @slot)) {
				@rule = @rules[@slot];
			} else if(array_index_exists(@rules, @slot - 9)) {
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
				} else {
					if(@rule['value'] >= @rule['min']) {
						@rule['value'] = mod(@rule['value'] + 1, @rule['max'] + 1)
					} else {
						@rule['value'] = @rule['min'];
					}
					if(@rule['value']) {
						@item['qty'] = @rule['value'];
						@item['data'] = 10;
						@item['meta']['display'] = color('green').'ACTIVATED';
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
