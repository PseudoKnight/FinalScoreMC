switch(@action) {
case 'load':
	bind('inventory_click', array('id': @player.'invclick'), array('player': @player), @event) {
		cancel();
	}
	
case 'unload':
	unbind(@player.'invclick');
}