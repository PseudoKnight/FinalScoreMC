proc _msg_charades(@message, @type = 'chat') {
	foreach(@t in get_teams('charades')) {
		foreach(@p in @t['players']) {
			if(@type == 'action') {
				action_msg(@p, color('black').@message);
			} else {
				tmsg(@p, @message);
			}
		}
	}
}
