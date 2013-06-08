# PMs, ignores, and mutes
bind('player_chat', null, null, @event,
	if(@event['message'] == '-') {
		cancel()
		die()
	}
	if(@event['message'][0] == '@') {
		@p = substr(parse_args(@event['message'])[0], 1)
		try(@player = player(@p),
			cancel()
			die('Player not found.')
		)
		if((length(@p) + 2) >= length(@event['message'])) {
			cancel()
			die()
		}
		@message = substr(@event['message'], length(@p) + 2)
		tmsg(@player, color(7).'(From '.player().'): '.color(r).colorize(@message))
		play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2), @player)
		msg(color(7).'(To '.@player.'): '.color(r).colorize(@message))
		console(player().' @ '.@player.': '.@message, false)
		@conv = import('conv')
		@conv[@player] = player()
		@conv[player()] = @player
		export('conv', @conv)
		cancel()
		die()
	}
	@ignorelist = import('ignorelist')
	if(array_index_exists(@ignorelist, player())) {
		@recipients = @event['recipients']
		for(@i = 0, @i < array_size(@ignorelist[player()]), @i++,
			if(@ignorelist[player()][@i] == 'all') {
				msg('You have been muted.')
				cancel()
				die()
			}
			for(@j = 0, @j < array_size(@recipients), @j++,
				if(@recipients[@j] == @ignorelist[player()][@i]) {
					array_remove(@recipients, @j)
				}
			)
		)
		modify_event('recipients', @recipients)
	}
	modify_event('message', colorize(@event['message']))
	modify_event('format', color('dark_gray').simple_date('h:mm').' '.if(array_contains(pgroup(), 'donors'), color('green').'\u2666 ')._colorname(player()).player().color('gray').': '.color('r').'%2$s')
)