// Open inventories without having to place them.
// While a convenience, this also helps players who are in protected regions where they can't place blocks.
bind('inventory_click', null, array('clicktype': 'SHIFT_RIGHT'), @event) {
	if(!@event['slotitem'] || !_is_survival_world(pworld())) {
		die();
	}
	switch(@event['slotitem']['name']) {
		case 'WORKBENCH':
			cancel();
			pworkbench();
		case 'ENDER_CHEST':
			cancel();
			play_sound(ploc(), array('sound': 'BLOCK_ENDERCHEST_OPEN'));
			show_enderchest();
		case 'ENCHANTMENT_TABLE':
			cancel();
			penchanting();
		default:
			if(@event['inventorytype'] == 'CRAFTING' && string_ends_with(@event['slotitem']['name'], '_SHULKER_BOX')) {
				if(!pisop()) {
					die(); // in testing
				}
				if(!@event['slotitem']['meta']) {
					@event['slotitem']['meta'] = array('inventory': associative_array(), 'display': null);
				}
				@inv = @event['slotitem']['meta']['inventory'];
				@inv['title'] = @event['slotitem']['meta']['display'] ||| 'Shulker Box';
				@inv['id'] = player().'shulkerbox';
				@inv['type'] = 'SHULKER_BOX';
				create_virtualchest(@inv);
				popen_virtualchest(player().'shulkerbox');
				bind('inventory_click', array('id': player().'shulkerbox', 'priority': 'HIGH'), array('player': player()), @event) {
					consume();
					if(@event['slotitem'] && string_ends_with(@event['slotitem']['name'], '_SHULKER_BOX')) {
						cancel();
					}
				}

				bind('virtualchest_closed', null,null, @event,
					@player = player(),
					@id = @inv['id'],
					@slot = @event['slot'],
					@item = @event['slotitem']
				) {
					if(@event['player'] == @player) {
						unbind();
						unbind(player().'shulkerbox');
						@item['meta']['inventory'] = get_virtualchest(@id);
						set_pinv(player(), @slot, @item);
						del_virtualchest(@id);
					}
				}
			}
	}
}
