proc _hazards_create_entity(@game, @type, @loc) {
    spawn_entity(@type, 1, @loc, closure(@entity) {
        set_entity_ai(@entity, false);
        @game['entities'][] = array(
            'loc': @loc,
            'type': @type,
            'uuid': @entity,
        );
    });
}

proc _hazards_remove_entity(@uuid, @game) {
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

proc _hazards_activate_entities(@game) {
    foreach(@index: @entity in @game['entities']) {
        if(entity_exists(@entity['uuid'])) {
            set_entity_ai(@entity['uuid'], true);
        } else {
            console('Entity doesn\'t exist when trying to activate it.');
            array_remove(@game['entities'], @index);
        }
    }
}

proc _hazards_respawn_entities(@game) {
    foreach(@index: @entity in @game['entities']) {
        if(entity_exists(@entity['uuid'])) {
            entity_remove(@entity['uuid']);
        }
        spawn_entity(@entity['type'], 1, @entity['loc'], closure(@uuid) {
            set_entity_ai(@uuid, false);
            @entity['uuid'] = @uuid;
        });
    }
}

proc _hazards_remove_entities(@game) {
    foreach(@index: @entity in @game['entities']) {
        if(entity_exists(@entity['uuid'])) {
            entity_remove(@entity['uuid']);
        }
    }
}
