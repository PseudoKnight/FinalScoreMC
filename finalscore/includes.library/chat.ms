proc _pmsg(@player, @message) {
	try(if(@player != '~console', @player = player(@player))
		if(@recipients = _remove_ignored(player(), array(@player))) {
			@player = @recipients[0]
			@message = colorize(@message)
			tmsg(@player, color(7).'(From '.player().'): '.color('r').@message)
			if(@player != '~console', play_sound(ploc(@player), array('sound': 'CHICKEN_EGG_POP', 'pitch': 2), @player))
			msg(color(7).'(To '.@player.'): '.color('r').@message)
			@conv = import('conv')
			@conv[@player] = player()
			@conv[player()] = @player
			export('conv', @conv)
		} else {
			msg('You cannot message that player.')
		}
	, # else
		@pdata = get_value('players', to_lower(@player))
		if(!@pdata, die(color('red').'Unknown player. If you wish to send an offline message, use their full name.'))
		if(!array_index_exists(@pdata, 'mail'), @pdata['mail'] = array())
		array_push(@pdata['mail'], array(
			simple_date('MMM d h:mm a', time(), 'CST'),
			player(),
			@message
		))
		store_value('players', to_lower(@player), @pdata)
		msg(color('green').'Offline message sent to '.@player)
		msg(color(7).'(To '.@player.'): '.color('r').@message)
	)
}

proc _remove_ignored(@sender, @recipients) {
	@ignorelist = import('ignorelist')
	for(@i = 0, @i < array_size(@recipients), @i++,
		if(array_index_exists(@ignorelist, @sender)) {
			if(array_contains(@ignorelist[@sender], @recipients[@i])) {
				array_remove(@recipients, @i)
			} else if(array_contains(@ignorelist[@sender], 'all')) {
				return(array())
			}
		}
		if(array_index_exists(@ignorelist, 'all')) {
			if(array_contains(@ignorelist['all'], @recipients[@i])) {
				array_remove(@recipients, @i)
			}
		}
	)
	return(@recipients)
}