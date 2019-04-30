@menu = @main[];
@menu[27]['name'] = 'RED_WOOL';

@menuPvp = array(
	'inv': associative_array(),
	'id': 'pvp',
	'title': 'PVP Arenas',
	'menu': @menu
);

@arenas = array_filter(get_values('arena'), closure(@key, @value){
	return(!array_index_exists(@value, 'parent'));
});
@slot = floor((27 - array_size(@arenas)) / 9) * 9;
foreach(@name: @arena in @arenas) {
	@name = split('.', @name)[1];
	@lore = array();
	@min = if(array_index_exists(@arena, 'min'), @arena['min'], 2);
	@max = if(array_index_exists(@arena, 'max'), '-'.@arena['max'], '+');
	@lore[] = color('green').@min.@max.' players';
	if(array_index_exists(@arena, 'description')) {
		foreach(@line in @arena['description']) {
			@lore[] = @line;
		}
	} else if(array_index_exists(@arena, 'mode')) {
		if(@arena['mode'] == 'koth') {
			@lore[] = color('green').'King of the Hill';
		} else if(@arena['mode'] == 'ctf') {
			@lore[] = color('green').'Capture the Flag';
		} else if(@arena['mode'] == 'bombingrun') {
			@lore[] = color('green').'Bombing Run';
		}
	}
	@lore[] = color('dark_gray').'Run: /warp '.@name;
	@menuPvp['inv'][@slot++] = associative_array(
		'name': 'GRAY_DYE',
		'meta': associative_array(
			'display': color('green').to_upper(@name),
			'lore': @lore,
			'flags': array('HIDE_ATTRIBUTES'),
		),
	);
}
export('menu.pvp', @menuPvp);

bind('world_changed', null, null, @event) {
	if(@event['from'] == 'custom' || @event['to'] == 'custom') {
		set_timeout(250, closure(_menu_refresh_pvp()));
	}
}

bind('player_join', null, array('world': 'custom'), @event) {
	set_timeout(250, closure(_menu_refresh_pvp()));
}
