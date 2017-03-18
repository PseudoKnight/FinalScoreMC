bind(player_interact, null, array('item': data_values('book'), 'button': 'right', 'hand': 'main_hand'), @event) {
	if(pworld() === 'custom') {
		@display = _item_meta(pinv(player(), null), 'display');
		if(@display === 'Park Directory') {
			cancel();
			popen_virtualchest('main');
			play_sound(ploc(), array('sound': 'STEP_WOOL', 'pitch': 1.2), player());
		}
	}
}

queue_push(closure(){
	include('includes.library/park.ms');
	_create_park_menu();
});
