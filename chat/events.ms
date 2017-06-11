if(!import('ignorelist')) {
	@ignorelist = get_value('session.ignorelist')
	if(!@ignorelist) {
		@ignorelist = associative_array();
	} else {
		clear_value('session.ignorelist');
	}
	export('ignorelist', @ignorelist);
}

if(!import('conv')) {
	@conv = get_value('session.conv')
	if(!@conv) {
		@conv = associative_array();
	} else {
		clear_value('session.conv');
	}
	export('conv', @conv);
}

# PMs, ignores, and mutes
bind(player_chat, null, null, @event) {
	cancel()
	include('includes.library/chat.ms')

	# PRIVATE MESSAGING
	if(@event['message'][0] === '@') {
		@p = substr(parse_args(@event['message'])[0], 1)
		if((length(@p) + 2) >= length(@event['message'])) {
			die()
		}
		@message = substr(@event['message'], length(@p) + 2)
		_pmsg(@p, @message)
		console(player().' @ '.@p.': '.@message, false)
		die()
	}

	# Remove players that are ignoring this player, or everyone if muted.
	@recipients = _remove_ignored(player(), @event['recipients']);
	if(array_size(@recipients) == 1 && array_size(all_players()) > 1) {
		die('No players can receive your chat.');
	}

	# Basic hostile word filters
	@filteredMessage = reg_replace('(?i)(fuck|shit|damn|nigg|cunt|fag)', '\u2639', @event['message']);

	# Chat escaping
	@escapedMessage = replace(@filteredMessage, '\\', '\\\\');
	@escapedMessage = replace(@escapedMessage, '"', '\\u0022');

	# Construct chat components
	@components = array();
	@components[] = array('colorize', '&8'.simple_date('h:mm').' ');

	@pdata = _pdata(player());
	if(array_index_exists(@pdata, 'support')) {
		@components[] = array('hover', '&a\u2666', 'Server Supporter');
	}

	@pstate = _pstate(player());
	if(array_index_exists(@pstate, 'trophies')) {
		@components[] = array('hover', '&6\u2660', '&6&lTrophies\n'.array_implode(@pstate['trophies'], '\n'));
	}

	if(array_index_exists(@pdata, 'icon')) {
		@components[] = array('plain', @pdata['icon']);
	}

	@color = _colorname();

	@components[] = array('hover', ' '.@color.player(),
		if(has_permission('group.moderator'), '&bSTAFF\n')
		.if(array_index_exists(@pdata, 'names'), @color.array_implode(@pdata['names']).'\n')
		.'&8[world] &r'._worldname(pworld()));
	@components[] = '&8: ';

	@components[] = '&r'.@escapedMessage;

	# Send chat message
	_tellraw(@recipients, @components);
	console(if(!@recipients, '[MUTED] ').player().': '.@event['message'], false);
	if(@recipients) {
		if(function_exists('dm_broadcast_to_web')) {
			dm_broadcast_to_web(@filteredMessage, player());
		}
	}
}