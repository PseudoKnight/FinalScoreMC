proc _prepare_arena(@pvp) {
    include('../../dungeon/core.library/generator.ms');
    _generate_dungeon('static', 'custom', 'static', 0);
}

proc _load_events(@id) {
    @pvp = import('pvp'.@id);
    @pvp['binds'][] = 'staticdeathnoise';
    bind('player_death', array('id': 'staticdeathnoise', 'priority': 'MONITOR'), null, @event) {
        play_named_sound(ploc(), associative_array('sound': 'entity.wolf.howl', 'pitch': 1.7, 'volume': 2));
    }
}
