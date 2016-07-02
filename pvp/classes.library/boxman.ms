switch(@action) {
case 'load':
	set_pheld_slot(@player, 0);
	bind(item_held, array('id': @player.'boxman'), null, @e, @p = @player) {
		if(@e['player'] == @p) {
			cancel();
		}
	}

	bind(inventory_click, array('id': @player.'boxmanclick'), array('player': @player), @e) {
		cancel();
	}

case 'unload':
	unbind(@player.'boxman');
	unbind(@player.'boxmanclick');

}
