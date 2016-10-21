include('../../dungeon/core.library/generator.ms');
_generate_dungeon('static', 'custom', 'static', 0);

@pvp['binds'][] = 'staticdeathnoise';
bind('player_death', array('id': 'staticdeathnoise', 'priority': 'MONITOR'), null, @event, @pvp) {
    if(array_index_exists(@pvp['players'], player()) && @pvp['players'][player()]['team'] == 1) {
        play_named_sound(ploc(), associative_array('sound': 'entity.wolf.howl', 'pitch': 1.7, 'volume': 2));
    }
}
