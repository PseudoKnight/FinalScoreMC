@menu = @main[];
@menu[@rows * 9]['name'] = 'RED_WOOL';

@menuPvp = array(
	'inv': associative_array(),
	'id': 'pvp',
	'title': 'PVP Arenas',
	'size': @rows * 9 + 9,
	'menu': @menu
);

@arenas = get_values('arena');
@arenas = array_filter(get_values('arena'), closure(@key, @value){
	if(!array_index_exists(@value, 'parent')) {
		return(true);
	}
	@parentKey = 'arena.'.@value['parent'];
	return(!array_index_exists(@arenas[@parentKey], 'arenaselect')
	|| !array_contains(@arenas[@parentKey]['arenaselect']['arenas'], split('.', @key)[1]));
});
@slot = floor((@rows * 9 - array_size(@arenas)) / 9) * 9;
foreach(@name: @arena in @arenas) {
	@name = split('.', @name)[1];
	@item = 'IRON_SWORD';
	@qty = 1;
	@lore = array();
	if(array_index_exists(@arena, 'mode')) {
		if(@arena['mode'] == 'koth') {
			@lore[] = color('green').'King of the Hill';
			@item = 'IRON_HELMET';
		} else if(@arena['mode'] == 'ctf') {
			@lore[] = color('green').'Capture the Flag';
			@item = 'WHITE_BANNER';
		} else if(@arena['mode'] == 'bombingrun') {
			@lore[] = color('green').'Bombing Run';
			@item = 'FIRE_CHARGE';
		}
	}
	if(array_index_exists(@arena, 'arenaselect')) {
		@qty = array_size(@arena['arenaselect']['arenas']);
		@lore[] = color('yellow').@qty.' arenas to '.if(@arena['arenaselect']['type'] == 'vote', 'choose from', 'play on');
	}
	@min = if(array_index_exists(@arena, 'min'), @arena['min'], 2);
	@max = if(array_index_exists(@arena, 'max'), '-'.@arena['max'], '+');
	@lore[] = color('green').@min.@max.' players';
	if(array_index_exists(@arena, 'description')) {
		foreach(@line in @arena['description']) {
			@lore[] = color('white').@line;
		}
	}
	@lore[] = color('dark_gray').'Run: /warp '.@name;
	@menuPvp['inv'][@slot++] = associative_array(
		'name': @item,
		'qty': @qty,
		'meta': associative_array(
			'display': color('green')._to_upper_camel_case(@name),
			'lore': @lore,
			'flags': array('HIDE_ATTRIBUTES', 'HIDE_ENCHANTS'),
		),
	);
}
export('menu.pvp', @menuPvp);

bind('world_changed', null, array(from: 'custom'), @event) {
	set_timeout(50, closure(_menu_refresh('pvp')));
}
