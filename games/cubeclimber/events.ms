# Calculate trophies
bind('player_join', null, null, @event) {
	queue_push(closure(){
		@uuid = null;
		try {
			@uuid = puuid(player(), true);
		} catch(PlayerOfflineException @ex) {
			return();
		}
		@toptimes = get_value('cubeclimber', 'toptimes');
		foreach(@i: @this in @toptimes) {
			if(@this[1] === @uuid) {
				@rank = '&e\u278A';
				switch(@i) {
					case 1:
						@rank = '&e\u278B';
					case 2:
						@rank = '&e\u278C';
					case 3:
						@rank = '&e\u278D';
					case 4:
						@rank = '&e\u278E';
					case 5:
						@rank = '&f\u278F';
					case 6:
						@rank = '&f\u2790';
					case 7:
						@rank = '&f\u2791';
					case 8:
						@rank = '&f\u2792';
					case 9:
						@rank = '&f\u2793';
					case 10:
						@rank = '&f\u24EB';
					case 11:
						@rank = '&f\u24EC';
					case 12:
						@rank = '&f\u24ED';
					case 13:
						@rank = '&f\u24EE';
					case 14:
						@rank = '&f\u24EF';
					case 15:
						@rank = '&f\u24F0';
					case 16:
						@rank = '&f\u24F1';
					case 17:
						@rank = '&f\u24F2';
					case 18:
						@rank = '&f\u24F3';
					case 19:
						@rank = '&f\u24F4';
				}
				@session = _psession(player());
				if(!array_index_exists(@session, 'trophies')) {
					@session['trophies'] = array();
				}
				@session['trophies'][] = @rank.' \u231B CubeClimber Time';
				break();
			}
		}

	}, 'trophies');
}
