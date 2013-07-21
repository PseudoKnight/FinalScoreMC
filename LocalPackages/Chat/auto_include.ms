proc('_pmsg', @player, @message,
	if(@player != '~console') {
		try(@player = player(@player), die('Player not found.'))
	}
	@message = colorize(@message)
	tmsg(@player, color('7').'(From '.player().'): '.color('r').@message)
	if(@player != '~console', play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2), @player))
	msg(color('7').'(To '.@player.'): '.color('r').@message)
	@conv = import('conv')
	@conv[@player] = player()
	@conv[player()] = @player
	export('conv', @conv)
)