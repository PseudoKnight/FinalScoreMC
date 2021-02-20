proc _hazard_create_entity(@game, @type, @loc) {
	spawn_entity(@type, 1, @loc, closure(@entity) {
		try(set_entity_ai(@entity, false));
		@game['entities'][] = array(
			loc: @loc,
			type: @type,
			uuid: @entity,
		);
	});
}

proc _hazard_remove_entity(@uuid, @game) {
	foreach(@index: @entity in @game['entities']) {
		if(@uuid == @entity['uuid']) {
			if(entity_exists(@uuid)) {
				entity_remove(@uuid);
			}
			array_remove(@game['entities'], @index);
			break();
		}
	}
}

proc _hazard_activate_entities(@game) {
	foreach(@index: @entity in @game['entities']) {
		if(entity_exists(@entity['uuid'])) {
			try(set_entity_ai(@entity['uuid'], true));
		} else {
			console('Entity doesn\'t exist when trying to activate it.');
			array_remove(@game['entities'], @index);
		}
	}
}

proc _hazard_respawn_entities(@game) {
	foreach(@index: @entity in @game['entities']) {
		if(entity_exists(@entity['uuid'])) {
			entity_remove(@entity['uuid']);
		}
		if(!array_index_exists(@entity, 'type')) {
			array_remove(@game['entities'], @index);
			continue();
		}
		spawn_entity(@entity['type'], 1, @entity['loc'], closure(@uuid) {
			try(set_entity_ai(@uuid, false));
			@entity['uuid'] = @uuid;
		});
	}
}

proc _hazard_remove_entities(@game) {
	foreach(@index: @entity in @game['entities']) {
		if(entity_exists(@entity['uuid'])) {
			entity_remove(@entity['uuid']);
		}
	}
}
