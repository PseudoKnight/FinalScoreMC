// Get a list of available arcade games
@arcadeGames = array();
foreach(@file in list_files('game.library')) {
	@arcadeGames[] = split('.', @file)[0];
}

/*
	Whenever a player interacts with a hidden item frame and it contains a filled map of an arcade game, load that game.
 */
bind('player_interact_entity', array(priority: 'MONITOR'), array(clicked: 'ITEM_FRAME', hand: 'main_hand'), @event, @arcadeGames) {
	if(is_cancelled()) {
		die();
	}
	@spec = entity_spec(@event['id']);
	if(@spec['visible']) {
		die();
	}
	@item = @spec['item'];
	if(!@item || @item['name'] !== 'FILLED_MAP') {
		die();
	}
	@meta = @item['meta'];
	if(!@meta || !@meta['lore']) {
		die();
	}
	@game = @meta['lore'][0];
	if(array_contains(@arcadeGames, @game)) {
		if(get_metadata(@event['id'], 'arcade', 'CommandHelper')) {
			die();
		}
		set_metadata(@event['id'], 'arcade', true);
		include_dir('util.library');
		proc _load_arcade_game(@itemFrameId) {}
		include("game.library/@game.ms");
		_load_arcade_game(@event['id']);
	}
}

/*
	Whenever a hidden item frame is hit and contains a filled map of an arcade game,
	the text display entities should be removed because the filled map will be removed.
 */
bind('entity_damage', array(priority: 'MONITOR'), array(type: 'ITEM_FRAME'), @event, @arcadeGames) {
	if(is_cancelled()) {
		die();
	}
	@spec = entity_spec(@event['id']);
	if(@spec['visible']) {
		die();
	}
	@item = @spec['item'];
	if(!@item || @item['name'] !== 'FILLED_MAP') {
		die();
	}
	@meta = @item['meta'];
	if(!@meta || !@meta['lore']) {
		die();
	}
	@game = @meta['lore'][0];
	if(array_contains(@arcadeGames, @game)) {
		// clear text display entities next to item frame entity
		foreach(@entity in entities_in_radius(entity_loc(@event['id']), 1, 'TEXT_DISPLAY')) {
			if(has_scoreboard_tag(@entity, 'arcade')) {
				entity_remove(@entity);
			}
		}
	}
}