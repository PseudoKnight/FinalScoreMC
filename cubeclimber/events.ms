# Calculate trophies
bind(player_join, null, null, @event) {
	queue_push(closure(){
		try {
			@uuid = puuid(player(), true);
		} catch(PlayerOfflineException @ex) {
			return();
		}
        @toptimes = get_value('cubeclimber', 'toptimes');
        foreach(@i: @this in @toptimes) {
            if(@this[0] == player()) {
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
                        @rank = '\u278F';
                    case 6:
                        @rank = '\u2790';
                    case 7:
                        @rank = '\u2791';
                    case 8:
                        @rank = '\u2792';
                    case 9:
                        @rank = '\u2793';
                    case 10:
                        @rank = '\u24EB';
                    case 11:
                        @rank = '\u24EC';
                    case 12:
                        @rank = '\u24ED';
                    case 13:
                        @rank = '\u24EE';
                    case 14:
                        @rank = '\u24EF';
					case 15:
						@rank = '\u24F0';
					case 16:
						@rank = '\u24F1';
					case 17:
						@rank = '\u24F2';
					case 18:
						@rank = '\u24F3';
					case 19:
						@rank = '\u24F4';
                }
                @pstate = _pstate(player());
                if(!array_index_exists(@pstate, 'trophies')) {
                    @pstate['trophies'] = array();
                }
                @pstate['trophies'][] = @rank.' \u231B CubeClimber Time';
                break();
            }
        }

	}, 'trophies');
}
