register_command('potion', array(
	'description': 'Creates custom potions.',
	'usage': '/potion <potionType> <potionEffect> [#seconds|true|false] [#strength|true|false]',
	'permission': 'command.items',
	'tabcompleter': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) == 1) {
			return(_strings_start_with_ic(array('potion', 'splash_potion', 'lingering_potion', 'tipped_arrow'), @args[-1]));
		} else if(array_size(@args) == 2) {
			return(_strings_start_with_ic(array_keys(_get_effects()), @args[-1]));
		}
		return(array());
	},
	'executor': closure(@alias, @sender, @args, @info) {
		if(array_size(@args) < 2) {
			return(false);
		}
		@type = to_upper(@args[0]);
		if(@type != 'POTION' && @type != 'SPLASH_POTION' && @type != 'LINGERING_POTION' && @type != 'TIPPED_ARROW') {
			die(color('gold').'First argument must be a potion type: potion, splash_potion, lingering_potion, or tipped_arrow.');
		}
		
		@id = @args[1];
		@effects = _get_effects();
		if(!is_numeric(@id)) {
			if(!array_index_exists(@effects, @id)) {
				die(color('yellow').'Available potion effects: '.@effects);
			}
			@id = @effects[@id];
		}
		
		@seconds = 30;
		@strength = 1;
		if(array_size(@args) > 2) {
			@seconds = @args[2];
			if(array_size(@args) > 3) {
				@strength = @args[3];
			}
		}

		@item = pinv(player(), null);
		if(@item && @item['name'] == @type) { # add potion effecs to potion
			if(is_null(@item['meta'])) {
				@item['meta'] = associative_array();
			}
			if(!array_index_exists(@item['meta'], 'potions')) {
				@item['meta']['potions'] = array();
			}
			@item['meta']['potions'][] = array('id': @id, 'strength': min(99, @strength - 1), 'seconds': @seconds);
			set_pinv(player(), null, @item);

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
				@item['meta']['potions'] = array(array('id': @id, 'strength': @strength - 1, 'seconds': @seconds));
			}
			set_pinv(player(), null, @item);
		}
	}
));
