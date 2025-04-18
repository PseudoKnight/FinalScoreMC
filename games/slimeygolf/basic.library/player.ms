proc _add_player(@player, @golf) {
	if(pmode(@player) === 'CREATIVE' || pmode(@player) === 'SPECTATOR' || !_set_pactivity(@player, @golf['name'])) {
		return(false);
	}
	@golf['players'][@player] = array(
		hole: array_get(@golf['currentHole'], @player, 1),
		id: 0,
		slime: 0,
		color: 0,
		size: 0.5,
		velocity: array(x: 0, y: 0, z: 0),
		swing: false,
		cooldown: 0,
		dyecolor: array_get_rand(reflect_pull('enum', 'DyeColor')),
	);
	set_pinv(@player, 0, array(name: 'SLIME_BALL'));
	set_pinv(@player, 1, array(name: @golf['players'][@player]['dyecolor'].'_DYE', meta: array(display: 'Color Changer')));
	set_pscoreboard(@player, @golf['name']);
	tmsg(@player, colorize(
		'&a&lSLIMEY&6&lGOLF &a\u2308\u2328 \uFE52\u2328\u2309&r\n'
		.'&6&l[ How to Play ]&r\n'
		.'- Place slime ball on white concrete.\n'
		.'- Right-click slime to start swing.\n'
		.'- As your swing charges, hit slime.'
	));
	return(true);
}

proc _remove_player(@player, @golf) {
	unbind('golf_swing1_'.@player);
	unbind('golf_swing2_'.@player);
	unbind('golf_hit_'.@player);
	@ball = @golf['players'][@player];
	_remove_ball(@ball['id'], @ball['slime']);
	if(ponline(@player)) {
		set_pscoreboard(@player);
		if(pworld(@player) == @golf['world']) {
			@item = pinv(@player, 0);
			if(@item && @item['name'] == 'SLIME_BALL') {
				set_pinv(@player, 0, null);
			}
			@item = pinv(@player, 1);
			if(@item && string_ends_with(@item['name'], 'DYE')) {
				set_pinv(@player, 1, null);
			}
		}
	}
	@hole = @ball['hole'];
	@lastplayer = true;
	foreach(@p: @b in @golf['players']) {
		if(@p != @player
		&& @b['hole'] <= @hole) {
			@lastplayer = false;
			break();
		}
	}
	if(@lastplayer) {
		try {
			set_block(@golf[@hole]['loc'], 'AIR');
		} catch(IndexOverflowException @ex) {
			// nothing to reset
		}
	}
	_set_pactivity(@player, null);
	array_remove(@golf['players'], @player);
	@golf['currentHole'][@player] = @hole;
}
