@pvp['binds'][] = @id.'snowballtp';
bind(entity_damage_player, array('id': @id.'snowballtp'), array('damager': 'SNOWBALL'), @e, @id) {
    @pvp = import('pvp'.@id)
    @player = @e['player'];
    @damager = @e['data'];
    if(!array_index_exists(@pvp['players'], @player)) {
        die();
    }
    if(array_index_exists(@pvp, 'team')
    && @pvp['players'][@player]['team'] == @pvp['players'][@damager]['team']) {
        die();
    }
    @loc = _relative(ploc(@player), 'up', 2);
    play_effect(@loc, 'SNOWBALL_BREAK', associative_array(
        'particleCount': 20,
        'offsetX': 0.5,
        'offsetY': 1,
        'offsetZ': 0.5,
    ));
    play_named_sound(@loc, associative_array('sound': 'entity.llama.spit', 'pitch': 0.5, 'volume': 2));
    @team = 0;
    if(array_index_exists(@pvp, 'team')) {
        @team = @pvp['players'][@player]['team'];
    }
    @loc = array_rand(@pvp['arena']['spawn'][@team], 1, false)[0];
    set_ploc(@player, @loc);
    play_named_sound(@loc, associative_array('sound': 'entity.llama.spit', 'pitch': 0.5), @player);
}

@pvp['binds'][] = @id.'snowballpickup';
bind(item_pickup, array('id': @id.'snowballpickup', 'priority': 'HIGHEST'), array('item': data_values('snowball')), @e, @id) {
    @pvp = import('pvp'.@id)
    if(!array_index_exists(@pvp['players'], player())) {
        die();
    }
    consume();
    if(!pinv(player(), 0)) {
        modify_event('item', null);
        set_pinv(player(), associative_array(0: associative_array('name': 'SNOW_BALL')));
    } else if(!pinv(player(), -106)) {
        modify_event('item', null);
        set_pinv(player(), associative_array(-106: associative_array('name': 'SNOW_BALL')));
    } else {
        cancel();
    }
}

@pvp['binds'][] = @id.'snowballshovel';
bind(player_interact, array('id': @id.'snowballshovel'), array('item': data_values('woodenshovel'), 'block': data_values('snow'), 'button': 'left'), @e, @id) {
    @pvp = import('pvp'.@id)
    if(!array_index_exists(@pvp['players'], player())) {
        die();
    }
    cancel();
    @loc = @e['location'];
    @loc['x'] += 0.5;
    @loc['y'] += 0.25;
    @loc['z'] += 0.5;
    @snowball = spawn_entity('DROPPED_ITEM', 1, @loc)[0];
    set_entity_spec(@snowball, associative_array('itemstack': associative_array('name': 'SNOW_BALL')));
}

@pvp['binds'][] = @id.'shovelbreak';
bind(block_break, array('id': @id.'shovelbreak'), null, @e, @id) {
    @pvp = import('pvp'.@id)
    if(!array_index_exists(@pvp['players'], player())) {
        die();
    }
    cancel();
}
