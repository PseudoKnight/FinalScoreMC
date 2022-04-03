proc _class_load(@player, @pvp) {
	bind('food_level_changed', array(id: @player.'noeat'), array(player: @player), @event) {
		cancel();
	}
}

proc _class_unload(@player, @pvp) {
	unbind(@player.'noeat');
}