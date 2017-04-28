proc _pgive_item(@item, @amount) {
	@item = split(':', @item);
	if(!is_numeric(@item[0])) {
		@item[0] = data_values(@item[0]);
	}
	if(is_null(@item[0])) {
		die('Unknown item name');
	}
	if(array_size(@item) == 1) {
		@item[1] = 0;
	}
	if(!is_integral(@amount) || @amount < 1) {
		die('Amount must be a positive integer.');
	}
	try {
		pgive_item(@item[0].':'.@item[1], @amount);
		msg(color('yellow').'You\'ve been given '.@amount.' '.data_name(@item[0].':'.@item[1]).'.');
	} catch(Exception @ex) {
		msg(color('red').'The item '.@item.' doesn\'t appear to exist.');
	}
}

proc _enchant_item(@type, @level) {
	# enchantment aliases
	@enchants = associative_array(
		'power': 'ARROW_DAMAGE',
		'flame': 'ARROW_FIRE',
		'infinity': 'ARROW_INFINITE',
		'punch': 'ARROW_KNOCKBACK',
		'sharpness': 'DAMAGE_ALL',
		'baneofarthropods': 'DAMAGE_ARTHROPODS',
		'smite': 'DAMAGE_UNDEAD',
		'efficiency': 'DIG_SPEED',
		'unbreaking': 'DURABILITY',
		'fireaspect': 'FIRE_ASPECT',
		'knockback': 'KNOCKBACK',
		'fortune': 'LOOT_BONUS_BLOCKS',
		'looting': 'LOOT_BONUS_MOBS',
		'respiration': 'OXYGEN',
		'protection': 'PROTECTION_ENVIRONMENTAL',
		'blastprotection': 'PROTECTION_EXPLOSIONS',
		'featherfalling': 'PROTECTION_FALL',
		'fireprotection': 'PROTECTION_FIRE',
		'projectileprotection': 'PROTECTION_PROJECTILE',
		'silktouch': 'SILK_TOUCH',
		'thorns': 'THORNS',
		'aquaaffinity': 'WATER_WORKER',
		'depthstrider': 'DEPTH_STRIDER',
		'mending': 'MENDING',
		'frostwalker': 'FROST_WALKER',
		'sweepingedge': 'SWEEPING_EDGE',
	);
	if(!is_integral(@level)) {
		die('Enchantment level must be an integer.');
	}
	if(array_index_exists(@enchants, to_lower(@type))) {
		enchant_inv_unsafe(null, @enchants[to_lower(@type)], @level);
	} else {
		msg(color('red').'Available enchantments: '.array_keys(@enchants));
	}
}

proc _pset_potion(@type, @id, @seconds, @strength){
	@type = to_upper(@type);
	if(@type != 'POTION' && @type != 'SPLASH_POTION' && @type != 'LINGERING_POTION' && @type != 'TIPPED_ARROW') {
		die(color('gold').'First argument must be a potion type: potion, splash_potion, lingering_potion, or tipped_arrow.');
	}

	@effects = _get_effects();
	if(!is_numeric(@id)) {
		if(!array_index_exists(@effects, @id)) {
			die('Available potion effects: '.@effects);
		}
		@id = @effects[@id];
	}

	@item = pinv(player(), null);
	if(@item && @item['name'] == @type) { # add potion effecs to potion
		if(is_null(@item['meta'])) {
			@item['meta'] = associative_array();
		}
		if(!array_index_exists(@item['meta'], 'potions')) {
			@item['meta']['potions'] = array();
		}
		@item['meta']['potions'][] = associative_array('id': @id, 'strength': @strength - 1, 'seconds': @seconds);
		set_pinv(array(null: @item));

	} else { # create new potion
		@extended = @seconds;
		@upgraded = @strength;
		@item = associative_array('name': @type, 'meta': associative_array());
		@potionTypes = array(
			'',
			'SPEED',
			'SLOWNESS',
			'',
			'',
			'STRENGTH',
			'INSTANT_HEAL',
			'INSTANT_DAMAGE',
			'JUMP',
			'',
			'REGEN',
			'',
			'FIRE_RESISTANCE',
			'WATER_BREATHING',
			'INVISIBILITY',
			'',
			'NIGHT_VISION',
			'',
			'WEAKNESS',
			'POISON',
			'',
			'',
			'',
			'',
			'',
			'',
			'LUCK',
			''
		);
		// verify valid regular potion
		if(@potionTypes[@id]
		&& (@extended == 'true' || @extended == 'false')
		&& (@upgraded == 'true' || @upgraded == 'false')) {
			@item['meta']['base'] = associative_array(
				'type': @potionTypes[@id],
				'extended': (@extended == 'true'),
				'upgraded': (@upgraded == 'true'),
			);
		} else {
			@item['meta']['potions'] = array(associative_array('id': @id, 'strength': @strength - 1, 'seconds': @seconds));
		}
		set_pinv(array(null: @item));
	}
}
