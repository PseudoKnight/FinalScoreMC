/*
	Messsages every player within a WorldGuard region
*/
proc _regionmsg(@region, @msg) {
	foreach(@player in all_players()) {
		if(array_contains(sk_current_regions(@player), @region)) {
			tmsg(@player, @msg);
		}
	}
}

/*
	Removes entities that are inside a region.

	@region: The WorldGuard region name.
	@types: Array of entity types to remove. Defaults to all but excluded types. Can override excluded types.
	@world: The world to remove the entities from. Defaults to 'custom'.
	@removeProtected: If true, will also remove conditionally protected entity types (e.g. ArmorStands). Defaults to false.
	@excludeTypes: An array of unconditionally excluded entity types.

	Returns: Number of entities removed.
*/
proc _remove_region_entities(
	@region,
	@world = 'custom',
	@types = array(),
	@removeProtected = false,
	@excludeTypes = array('PLAYER', 'COMPLEX_PART', 'GLOW_ITEM_FRAME', 'ITEM_FRAME', 'PAINTING', 'TEXT_DISPLAY', 'UNKNOWN')
) {
	if(!sk_region_exists(@world, @region)) {
		console('Can\'t remove entities because region doesn\'t exist: '.@region, false);
		return(0);
	}
	@count = 0;
	foreach(@entity in all_entities(@world)) {
		@type = entity_type(@entity);
		if(!@types && !array_contains(@excludeTypes, @type) || array_contains(@types, @type)) {
			@loc = entity_loc(@entity);
			if(!array_contains(sk_regions_at(@loc), @region)) {
				continue();
			}
			if(@type === 'ARMOR_STAND' && !@removeProtected) {
				if(!has_scoreboard_tag(@entity, 'remove')) {
					continue();
				}
			}
			try {
				entity_remove(@entity);
				@count++;
			} catch(BadEntityException @ex) {
				console('Entity not found when trying to remove from region.', false);
				console('Region: '.@region.', EntityID: '.@entity, false);
			}
		}
	}
	return(@count);
}