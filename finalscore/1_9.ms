bind(block_break, null, array('type': data_values('deadbush')), @event) {
	if(!sk_can_build(@event['location'])) {
		die();
	}
	@qty = rand(3);
	if(@qty) {
		modify_event('drops', array(array('name': 'STICK', 'qty': @qty)));
	}
}