bind('entity_damage', null, array(type: '/(ITEM_FRAME|GLOW_ITEM_FRAME)/'), @event) {
	if(@event['cause'] === 'PROJECTILE') {
		if(@event['damagertype'] === 'ENDER_PEARL' || !_is_survival_world(@event['world'])) {
			cancel();
			die();
		}
	}
	if(!entity_spec(@event['id'])['visible']) {
		// check if item was removed a tick later
		set_timeout(50, closure(){
			try {
				if(!entity_spec(@event['id'])['item']) {
					entity_remove(@event['id']);
					if(!array_index_exists(@event, 'damager') || length(@event['damager']) > 17
					|| pmode(@event['damager']) !== 'CREATIVE') {
						drop_item(_center(@event['location']), array(name: @event['type']), false);
					}
				}
			} catch (BadEntityException @ignore) {
				// was damaged and then destroyed within 50ms
			}
		});
	}
}
