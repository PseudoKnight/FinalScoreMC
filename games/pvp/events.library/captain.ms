proc _bind(@pvp) {
	@id = @pvp['id'];

	@pvp['binds'][] = bind('item_pickup', null, null, @e, @pvp, @id) {
		if(!array_index_exists(@pvp['players'], player())) {
			die();
		}

		if(@e['item']['name'] == @pvp['team'][0]['captainhat']['name']) {
			consume();
			if(@pvp['players'][player()]['team'] == 0) {
				modify_event('item', null);
				_classes_unload(player(), @pvp['players'][player()]['class'], @pvp);
				_clear_pinv();
				clear_peffects();
				queue_clear(@id.'0hat');
				@pvp['players'][player()]['class'] = @pvp['arena']['captain'][0];
				@pvp['team'][0]['captain'] = player();
				_classes_load(player(), @pvp['players'][player()]['class'], @pvp);
				_classes_equip(player(), @pvp['players'][player()]['class'], @pvp);
				_pvp_msg(@pvp, color('gray').'[PVP] '
					.@pvp['arena']['team'][0]['color'].player().color('r').' became the new captain!');
				set_inventory_item(@id.'0', 0, null);
			} else {
				cancel();
			}

		} else if(@e['item']['name'] == @pvp['team'][1]['captainhat']['name']) {
			consume();
			if(@pvp['players'][player()]['team'] == 1) {
				modify_event('item', null);
				_classes_unload(player(), @pvp['players'][player()]['class'], @pvp);
				_clear_pinv();
				clear_peffects();
				queue_clear(@id.'1hat');
				@pvp['players'][player()]['class'] = @pvp['arena']['captain'][1];
				@pvp['team'][1]['captain'] = player();
				_classes_load(player(), @pvp['players'][player()]['class'], @pvp);
				_classes_equip(player(), @pvp['players'][player()]['class'], @pvp);
				_pvp_msg(@pvp, color('gray').'[PVP] '
					.@pvp['arena']['team'][1]['color'].player().color('r').' became the new captain!');
				set_inventory_item(@id.'1', 0, null);
			} else {
				cancel();
			}
		}
	}

	@pvp['binds'][] = bind('entity_damage', null, array(type: 'DROPPED_ITEM'), @event, @region = @pvp['arena']['region']) {
		if(sk_region_contains(@region, entity_loc(@event['id']))) {
			cancel();
		}
	}
}