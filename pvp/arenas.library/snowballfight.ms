@pvp['binds'][] = @id.'snowballtp';
bind(entity_damage_player, array('id': @id.'snowballtp'), array('damager': 'SNOWBALL'), @e, @id) {
    @pvp = import('pvp'.@id)
    @player = @e['player'];
    @damager = @e['data'];
    if(!array_index_exists(@pvp['players'], @player)) {
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
        @teamName =  @pvp['arena']['team'][@team]['name'];
        @score = get_pscore('score', @teamName, @id);
        set_pscore('score', @teamName, @score + 1, @id);
    } else {
        @score = get_pscore('score', @damager, @id);
        set_pscore('score', @damager, @score + 1, @id);
    }
    @loc = array_rand(@pvp['arena']['spawn'][@team], 1, false)[0];
    set_ploc(@player, @loc);
    _pvp_check_objectives(@id);
}
