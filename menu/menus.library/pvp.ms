proc _prepare_menu(@template) {
	@menu = @template[];
	@menu['id'] = 'pvp';
	@menu['title'] = 'PVP Arenas';
	@menu[57]['name'] = 'DIAMOND_SWORD';
	
	@menuPvp = array(
		'inv': array(),
		'lastCount': 0,
		'menu': @menu
	);
	
	@arenas = get_values('arena');
	foreach(@name: @arena in @arenas) {
		if(array_index_exists(@arena, 'parent'), continue());
		@name = split('.', @name)[1];
		@lore = array();
		if(array_index_exists(@arena, 'description')) {
			foreach(@line in @arena['description']) {
				@lore[] = @line;
			}
		} else if(array_index_exists(@arena, 'mode')) {
			if(@arena['mode'] == 'koth') {
				@lore[] = color('green').'King of the Hill';
			} else if(@arena['mode'] == 'ctf') {
				@lore[] = color('green').'Capture the Flag';
			}
		}
		@min = if(array_index_exists(@arena, 'min'), @arena['min'], 2);
		@lore[] = color('green').@min
				.if(array_index_exists(@arena, 'max'), '-'.@arena['max'], '+').' players';
		@lore[] = color('dark_gray').'Run: /warp '.@name;
		@menuPvp['inv'][] = associative_array(
			'type': 306,
			'qty': @min,
			'meta': associative_array(
				'display': color('green').to_upper(@name),
				'lore': @lore,
				'flags': array('HIDE_ATTRIBUTES'),
			),
		);
	}
	export('menu.pvp', @menuPvp);
}

proc _refresh_menu() {
	@menuPvp = import('menu.pvp');
	@count = array_size(all_players('custom'));
	if(@count == @menuPvp['lastCount']) {
		return();
	}
	@menuPvp['lastCount'] = @count;
	@menu = @menuPvp['menu'][];
	@i = 0;
	foreach(@item in @menuPvp['inv']) {
		if(@item['qty'] <= @count) {
			@menu[@i] = @item;
			@i++;
		}
	}
	create_virtualchest(@menu);
}