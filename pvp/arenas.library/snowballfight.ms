@pvp['binds'][] = @id.'snowballtp';
bind(entity_damage_player, array('id': @id.'snowballtp'), array('damager': 'SNOWBALL'), @e, @id) {
    @pvp = import('pvp'.@id)
    @player = @e['player'];
    @damager = @e['data'];
    if(!array_index_exists(@pvp['players'], @player)) {
        die();
    }
    if(array_index_exists(@pvp['players'], @damager)) {
        if(array_index_exists(@pvp, 'team')
        && @pvp['players'][@player]['team'] == @pvp['players'][@damager]['team']) {
            die();
        }
        @pvp['stats'][@damager]['kills']++;
    }
    @pvp['stats'][@player]['deaths']++;
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
    _pvp_equip(@id, @player);
}

@pvp['binds'][] = @id.'snowmanhit';
bind(entity_damage, array('id': @id.'snowmanhit'), array('type': 'SNOWMAN', 'cause': 'PROJECTILE', 'world': @pvp['arena']['lobby'][3]), @e, @id) {
    @loc = entity_loc(@e['id']);
    @loc['y'] += 1;
    play_sound(@loc, array('sound': 'ZOMBIE_INFECT'));
    play_effect(@loc, 'cloud', array('speed': 0, 'particleCount': 10, 'offsetX': 0.4, 'offsetZ': 0.4, 'offsetY': 0.4));
    entity_remove(@e['id']);
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
        play_sound(ploc(), associative_array('sound': 'ITEM_PICKUP', 'pitch': 2, 'volume': 0.5), player());
        @pvp['stats'][player()]['pickups']++;
    } else if(!pinv(player(), -106)) {
        modify_event('item', null);
        set_pinv(player(), associative_array(-106: associative_array('name': 'SNOW_BALL')));
        play_sound(ploc(), associative_array('sound': 'ITEM_PICKUP', 'pitch': 2, 'volume': 0.5), player());
        @pvp['stats'][player()]['pickups']++;
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
    @loc['y'] += 0.9;
    @loc['z'] += 0.5;
    @snowball = spawn_entity('DROPPED_ITEM', 1, @loc)[0];
    set_entity_spec(@snowball, associative_array('itemstack': associative_array('name': 'SNOW_BALL')));
    play_sound(@loc, associative_array('sound': 'DIG_SNOW', 'pitch': 0.8));
}

@pvp['binds'][] = @id.'shovelbreak';
bind(block_break, array('id': @id.'shovelbreak'), null, @e, @id) {
    @pvp = import('pvp'.@id)
    if(!array_index_exists(@pvp['players'], player())) {
        die();
    }
    cancel();
}
