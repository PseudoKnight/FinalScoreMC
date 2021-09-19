// Open inventories without having to place them.
// While a convenience, this also helps players who are in protected regions where they can't place blocks.
bind('inventory_click', null, array('clicktype': 'SHIFT_RIGHT'), @event) {
	if(!@event['slotitem'] || !_is_survival_world(pworld())) {
		die();
	}
	switch(@event['slotitem']['name']) {
		case 'CRAFTING_TABLE':
			cancel();
			pworkbench();
		case 'ENDER_CHEST':
			cancel();
			play_sound(ploc(), array('sound': 'BLOCK_ENDER_CHEST_OPEN'));
			show_enderchest();
		case 'ENCHANTMENT_TABLE':
			cancel();
			penchanting();
		default:
			if(@event['inventorytype'] == 'CRAFTING' && string_ends_with(@event['slotitem']['name'], 'SHULKER_BOX')) {
				if(!import('test_shulker_box')) {
					// In testing.
					// Currently there's a bug where chests with meta will cause an NPE.
					// This would need to be fixed in Spigot or worked around in CH before we can re-enabled this.
					die();
				}
				if(!@event['slotitem']['meta']) {
					@event['slotitem']['meta'] = array('inventory': associative_array(), 'display': null);
				}
				@inv = @event['slotitem']['meta']['inventory'];
				@title = @event['slotitem']['meta']['display'] ||| 'Shulker Box';
				@id = player().'shulkerbox';
				create_virtual_inventory(@id, 'SHULKER_BOX', @title, @inv);
				cancel();
				popen_inventory(player().'shulkerbox');
				bind('inventory_click', array('id': player().'shulkerbox', 'priority': 'HIGH'), array('player': player()), @event) {
					consume();
					if(@event['slotitem'] && string_ends_with(@event['slotitem']['name'], 'SHULKER_BOX')) {
						cancel();
					}
				}

				bind('inventory_close', null, null, @event,
					@player = player(),
					@id,
					@slot = @event['slot'],
					@item = @event['slotitem']
				) {
					if(@event['player'] == @player) {
						unbind();
						unbind(player().'shulkerbox');
						@item['meta']['inventory'] = get_inventory(@id);
						set_pinv(player(), @slot, @item);
						delete_virtual_inventory(@id);
					}
				}
			}
	}
}
