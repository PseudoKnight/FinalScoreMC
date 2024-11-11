/*
	Any primed TNT tagged with 'nodamage' will not break any blocks.
	This is primarily useful for when setting the source of the TNT to a player.
	In some cases that source will have region privileges, but we don't want destruction.
 */
bind('entity_explode', null, array(type: 'PRIMED_TNT'), @event) {
	if(has_scoreboard_tag(@event['id'], 'nodamage')) {
		modify_event('blocks', array());
	}
}