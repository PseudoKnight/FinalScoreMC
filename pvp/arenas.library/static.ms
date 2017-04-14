proc _prepare_arena(@pvp) {
    include('../../dungeon/core.library/generator.ms');
    _generate_dungeon('static', 'custom', 'static', 0);
}

proc _load_events(@id) {
    @pvp = import('pvp'.@id);
    @pvp['binds'][] = 'staticdeathnoise';
    bind('player_death', array('id': 'staticdeathnoise', 'priority': 'HIGHEST'), null, @event, @pvp) {
        if(array_index_exists(@pvp['players'], player())) {
            if(@pvp['players'][player()]['team'] == 1) {
                play_named_sound(ploc(), associative_array('sound': 'entity.wolf.howl', 'pitch': 1.7, 'volume': 3));
            	@stand = spawn_entity('ARMOR_STAND', 1, @event['location'])[0];
            	set_entity_spec(@stand, array(
            		'arms': true,
            		'baseplate': false,
            		'poses': array(
            				'poseArmLeft': array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
            				'poseArmRight': array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
            				'poseHead': array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
            				'poseLegLeft': array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
            				'poseLegRight': array(rand() - 0.5, rand() - 0.5, rand() - 0.5),
            			)
            	));
            } else {
                play_named_sound(ploc(), associative_array('sound': 'entity.vex.death', 'pitch': 0.5, 'volume': 3));
            }
        }
    }
}
