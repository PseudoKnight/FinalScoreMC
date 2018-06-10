bind('inventory_click', null, array('slottype': 'ARMOR'), @event) {
	if(@event['slot'] == 39
	&& @event['cursoritem']
	&& !string_ends_with(@event['cursoritem']['name'], 'HELMET')) {
		cancel();
		switch(@event['action']) {
			case 'PLACE_ONE':
				@item = @event['cursoritem'][];
				@item['qty'] = 1;
				@event['cursoritem']['qty']--;
				set_pinv(player(), 103, @item);
				modify_event('cursoritem', @event['cursoritem']);
			default:
				set_pinv(player(), 103, @event['cursoritem']);
				modify_event('cursoritem', @event['slotitem']);
		}
	}
}
