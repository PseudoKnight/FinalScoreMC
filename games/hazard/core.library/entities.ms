proc _hazard_create_entity(@game, @type, @loc, @spawner = null, @data = null) {
	@uuid = _hazard_spawn_entity(@type, @loc, @data);
	_hazard_add_entity(@game, @uuid, @type, @loc, @spawner, @data);
}

proc _hazard_spawn_entity(@type, @loc, @data) {
	@entity = null;
	if(@type === 'DROPPED_ITEM') {
		@entity = drop_item(@loc, @data, false);
		set_entity_velocity(@entity, null);
	} else {
		@entity = spawn_entity(@type, 1, @loc, closure(@e) {
			if(is_entity_living(@e)) {
				set_entity_ai(@e, false);
				set_entity_silent(@e, true);
			}
			if(array_contains(array('BOGGED', 'DROWNED', 'SKELETON', 'STRAY', 'ZOMBIE', 'ZOMBIE_VILLAGER'), @type)) {
				set_mob_equipment(@e, array(helmet: array(name: 'LEATHER_HELMET')));
			} else if(@type === 'PHANTOM') {
				set_mob_effect(@e, 'FIRE_RESISTANCE', 1, 9999, true, false);
			}
		})[0];
	}
	return(@entity);
}

proc _hazard_add_entity(@game, @uuid, @type = null, @loc = null, @spawner = null, @data = null) {
	@game['entities'][] = array(
		uuid: @uuid,
		type: @type,
		loc: @loc,
		spawner: @spawner,
		data: @data,
	);
}

proc _hazard_remove_entity(@game, @uuid, @removeFromWorld = true) {
	foreach(@index: @entity in @game['entities']) {
		if(@uuid == @entity['uuid']) {
			if(@removeFromWorld && entity_exists(@uuid)) {
				entity_remove(@uuid);
			}
			array_remove(@game['entities'], @index);
			break();
		}
	}
}

proc _hazard_entity_spawner(@game, @uuid) {
	foreach(@index: @entity in @game['entities']) {
		if(@uuid == @entity['uuid']) {
			return(@entity['spawner']);
		}
	}
	return(null);
}

proc _hazard_activate_entities(@game) {
	foreach(@index: @entity in @game['entities']) {
		if(entity_exists(@entity['uuid'])) {
			if(is_entity_living(@entity['uuid'])) {
				set_entity_ai(@entity['uuid'], true);
				set_entity_silent(@entity['uuid'], false);
			}
		} else {
			if(@entity['type'] !== 'DROPPED_ITEM') {
				console('Entity doesn not exist when trying to activate it.');
			}
			array_remove(@game['entities'], @index);
		}
	}
}

proc _hazard_respawn_entities(@game) {
	foreach(@index: @entity in @game['entities']) {
		if(!@entity['type']) {
			array_remove(@game['entities'], @index);
			continue();
		}
		@entity['uuid'] = _hazard_spawn_entity(@entity['type'], @entity['loc'], @entity['data']);
	}
}

proc _hazard_remove_entities(@game) {
	foreach(@index: @entity in @game['entities']) {
		if(entity_exists(@entity['uuid'])) {
			entity_remove(@entity['uuid']);
		}
	}
}
