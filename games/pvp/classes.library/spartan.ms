proc _class_load(@player, @pvp) {
	bind('entity_damage', array(id: @player.'falldamage'), array(type: 'PLAYER', cause: 'FALL'), @event, @p = @player) {
		if(@event['player'] === @p) {
			cancel();	
		}
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'falldamage');
}
