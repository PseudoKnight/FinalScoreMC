@ignorelist = get_value('session.ignorelist')
if(!@ignorelist) {
	@ignorelist = array()
} else {
	clear_value('session.ignorelist')
}
export('ignorelist', @ignorelist)

@conv = get_value('session.conv')
if(!@conv) {
	@conv = array()
} else {
	clear_value('session.conv')
}
export('conv', @conv)

@staffchat = get_value('session.staffchat')
if(!@staffchat) {
	@staffchat = array()
} else {
	clear_value('session.staffchat')
}
export('staffchat', @staffchat)

# PMs, ignores, and mutes
bind(player_chat, null, null, @event) {
	cancel()
	include('includes.library/chat.ms')

	# PRIVATE MESSAGING
	if(@event['message'][0] == '@') {
		@p = substr(parse_args(@event['message'])[0], 1)
		if((length(@p) + 2) >= length(@event['message'])) {
			die()
		}
		@message = substr(@event['message'], length(@p) + 2)
		_pmsg(@p, @message)
		console(player().' @ '.@p.': '.@message, false)
		die()
	}
	
	# STAFF CHAT CHANNEL
	@staffchat = import('staffchat')
	if(array_contains(@staffchat, player())) {
		if(@event['message'][0] == '!') {
			@event['message'] = substr(@event['message'], 1)
		} else {
			broadcast(color('dark_gray').simple_date('h:mm').' '.color('aqua').'[STAFF] '.if(array_contains(pgroup(), 'supporters'), color('green').'\u2666 ')
				._colorname().player().color('gray').': '.color('r').colorize(@event['message']), 'chat.staff')
			die()
		}
	}
	
	# Remove players that are ignoring this player, or everyone if muted.
	@recipients = _remove_ignored(player(), @event['recipients']);
	if(array_size(@recipients) == 1 && array_size(all_players()) > 1) {
		die('No players can receive your chat.');
	}

	# Basic swear filter.
	@filteredMessage = reg_replace('(?i)(fuck|shit|damn|nigg|cunt|fag)', '****', @event['message']);
	
	# Chat escaping
	@escapedMessage = replace(@filteredMessage, '\\', '\\\\');
	@escapedMessage = replace(@escapedMessage, '"', '\\u0022');
	
	# Construct chat components
	@components = array();
	@components[] = '&8'.simple_date('h:mm').' ';
	
	@pdata = _pdata(player());
	if(array_index_exists(@pdata, 'support')) {
		@components[] = array('&a\u2666 ', 'Server Supporter');
	}
	
	@components[] = array(_colorname().player().'&8: ', 
		if(has_permission('group.moderators'), '&bSTAFF\n')
		.if(array_index_exists(@pdata, 'names'), '&8[aliases] &r'.array_implode(@pdata['names']).'\n')
		.'&8[world] &r'._worldname(pworld()));

	@clickableMessage = _clickable_links(@escapedMessage);
	
	@components[] = @clickableMessage.'&r';
	
	# Send chat message 
	_hover_tell(@recipients, @components);
	console(if(!@recipients, '[MUTED] ').player().': '.@event['message'], false);
	if(@recipients) {
		if(function_exists('dm_broadcast_to_web')) {
			dm_broadcast_to_web(@filteredMessage, player());
		}
	}
}