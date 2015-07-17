bind(block_break, null, array('type': data_values('deadbush')), @event) {
	@qty = rand(3);
	if(@qty) {
		modify_event('drops', array(array('name': 'STICK', 'qty': @qty)));
	}
}