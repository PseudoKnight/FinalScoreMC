proc _msg_charades(@message, @type = 'chat', @ignored = '') {
	foreach(@t in get_teams('charades')) {
		foreach(@p in @t['players']) {
			if(@p == @ignored || !ponline(@p)) {
				continue();
			}
			if(@type == 'action') {
				action_msg(@p, color('black').@message);
			} else {
				tmsg(@p, @message);
			}
		}
	}
}

proc _check_players(@charades) {
	@players = array();
	foreach(@p in all_players('custom')) {
		if(array_contains(sk_current_regions(@p), 'charades')) {
			if(!array_contains(@charades['players'], @p) && get_pscore('score', @p, 'charades') == 0) {
				return(false);
			} else {
				@players[] = @p;
			}
		}
	}
	if(array_size(@players) < 3) {
		return(false);
	}
	@charades['players'] = @players;
	return(true);
}
