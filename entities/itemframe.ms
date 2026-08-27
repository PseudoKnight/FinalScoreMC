/*
	Trim frames from item frames.
	Opens inventories blocked by trimmed item frames. (warning: can open blocked chests)
 */
bind('player_interact_entity', null, array(clicked: '/(ITEM_FRAME|GLOW_ITEM_FRAME)/'), @event) {
	@itemFrame = @event['id'];
	if(sk_can_build(entity_loc(@itemFrame))) {
		@data = entity_spec(@itemFrame);
		@slot = if(@event['hand'] === 'main_hand', null, -106);
		@item = pinv(player(), @slot);
		if(@item && @item['name'] === 'SHEARS' && @data['visible'] && @data['item']) {
			cancel();
			set_entity_spec(@itemFrame, array(visible: false));

			play_sound(@itemFrame, array(sound: 'ITEM_SHEARS_SNIP'));
			@particle = array(
				particle: 'ITEM_CRACK',
				count: 8,
				item: @event['clicked'],
				speed: 0.05,
				yoffset: 0.8,
				xoffset: 0.8,
				zoffset: 0.8);
			switch(get_hanging_direction(@event['id'])) {
				case 'UP':
				case 'DOWN':
					@particle['yoffset'] = 0.0;
				case 'NORTH':
				case 'SOUTH':
					@particle['zoffset'] = 0.0;
				case 'EAST':
				case 'WEST':
					@particle['xoffset'] = 0.0;
			}
			spawn_particle(entity_loc(@event['id']), @particle);

			if(!@item['meta']) {
				@item['meta'] = array(damage: 0);
			}
			@item['meta']['damage']++;
			if(@item['meta']['damage'] >= 238) {
				set_pinv(player(), @slot, null);

				@loc = location_shift(ploc(), 'up', 2.3);
				play_sound(@loc, array(sound: 'ITEM_SHIELD_BREAK'));
				@v = get_vector(@loc, 0.4);
				@loc['x'] += @v['x'];
				@loc['y'] += @v['y'];
				@loc['z'] += @v['z'];
				spawn_particle(@loc, array(
					particle: 'ITEM_CRACK',
					count: 3,
					item: 'SHEARS',
					speed: 0.1));

			} else {
				set_pinv(player(), @slot, @item);
			}

		} else if(!@data['visible'] && !psneaking()) {
			@dir = switch(get_hanging_direction(@event['id'])) {
				case 'UP': 'DOWN'
				case 'DOWN': 'UP'
				case 'NORTH': 'SOUTH'
				case 'SOUTH': 'NORTH'
				case 'EAST': 'WEST'
				case 'WEST': 'EAST'
			}
			@loc = location_shift(entity_loc(@event['id']), @dir);
			// Open viewable inventory types
			if(has_inventory(@loc) && get_inventory_size(@loc) >= 3 && sk_can_build(@loc)) {
				@type = get_inventory_type(@loc);
				if(@type !== 'CHISELED_BOOKSHELF' && @type !== 'SHELF') {
					cancel();
					popen_inventory(@loc);
				}
			}
		}
	}
}