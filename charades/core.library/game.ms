include('rounds.ms');
include('utils.ms');
include('events.ms');

proc _end_game() {
	@charades = import('charades');
	if(@charades['interval']) {
		clear_task(@charades['interval']);
	}
	
	@center = sk_region_info('charades-beacon', 'custom', 0)[0];
	set_block_at(@center, '95:3');
	play_sound(@center, array('sound': 'UI_TOAST_CHALLENGE_COMPLETE', 'volume': 5));
	
	@top = 0;
	@topPlayers = array();
	@warp = get_value('warp.charades');
	foreach(@t in get_teams('charades')) {
		foreach(@p in @t['players']) {
			@s = get_pscore('score', @p, 'charades');
			if(@s > @top) {
				@top = @s;
				foreach(@index: @player in @topPlayers) {
					array_remove(@topPlayers, @index);
				}
				@topPlayers[] = @p;
			} else if(@s == @top) {
				@topPlayers[] = @p;
			}
			set_ploc(@p, @warp);
			_equip_kit(@p);
		}
	}
	
	if(array_size(@topPlayers) == 1) {
		_regionmsg('charades', color('green').@topPlayers[0].' wins!');
	} else if(array_size(@topPlayers) > 1) {
		_regionmsg('charades', color('green').array_implode(@topPlayers, ' and ').' tied for the win!');
	} else {
		_regionmsg('charades', color('yellow').'Nobody wins! I\'M NOT SURE HOW THIS IS POSSIBLE. IS ANYONE THERE? WHY AM I YELLING?!');
	}
	_unbind_charade_events();
	export('charades', null);
	remove_scoreboard('charades');
}
