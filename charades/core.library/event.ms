proc _bind_charade_events() {
	bind(item_pickup, array('id': 'charades-pickup'), null, @event) {
		if(array_contains(sk_current_regions(), 'charades')) {
			cancel();
		}
	}
}

proc _unbind_charade_events() {
	unbind('charades-pickup');
}
