switch(@action) {
case 'load':
	bind('food_level_changed', array(id: @player.'noeat'), array(player: @player), @event) {
		cancel();
	}
	
case 'unload':
	unbind(@player.'noeat');
	
}