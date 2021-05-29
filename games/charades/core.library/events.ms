proc _bind_charade_events() {
	bind('item_pickup', array('id': 'charades-pickup'), null, @event) {
		if(array_contains(sk_current_regions(), 'charades')) {
			cancel();
		}
	}
	
	bind('sign_changed', array('id': 'charades-sign'), null, @event) {
		if(get_pscoreboard(player()) == 'charades' && get_pteam(player(), 'charades')['name'] == 'builder') {
			@text = @event['text'];
			foreach(@num: @line in @text) {
				@newline = reg_replace('[a-zA-Z0-9]', '', @line);
				@text[@num] = @newline;
			}
			modify_event('text', @text);
		}
	}
}

proc _unbind_charade_events() {
	unbind('charades-pickup');
	unbind('charades-sign');
}
