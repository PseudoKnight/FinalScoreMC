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
	cancel();
	include('includes.library/chat.ms');
	_chat(@event['player'], @event['message'], @event['recipients']);
}
