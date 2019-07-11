proc _hazards_add_player(@player, @game) {
    @game['players'][@player] = array(
        'score': 0,
    );
    set_pscoreboard(@player, 'hazards');
    bar_add_player('hazards', @player);
}

proc _hazards_remove_player(@player, @game) {
    array_remove(@game['players'], @player);
    if(ponline(@player)) {
        set_ploc(@player, get_value('warp.hazards'));
        bar_remove_player('hazards', @player);
        set_pscoreboard(@player);
        _equip_kit(@player);
    }
}

proc _hazards_spawn_players(@game) {
    @coords = sk_region_info('hazards_start', @game['world'], 0);
    foreach(@player: @data in @game['players']) {
        if(ponline(@player)) {
            @loc = array(rand(@coords[1][0] + 1, @coords[0][0]) + 0.5, @coords[1][1], rand(@coords[1][2] + 1, @coords[0][2]) + 0.5, @game['world']);
            set_ploc(@player, @loc);
            set_pbed_location(@player, @loc);
            set_phealth(@player, 1);
            set_phunger(@player, 16);
            set_psaturation(@player, 0);
            if(pmode(@player) == 'ADVENTURE') {
                play_sound(@loc, array('sound': 'ENTITY_FIREWORK_ROCKET_BLAST'), @player);
            }
        }
    }
}

proc _hazards_set_mode(@game, @mode) {
    foreach(@player: @data in @game['players']) {
        if(ponline(@player)) {
            set_pmode(@player, @mode);
        }
    }
}

proc _hazards_msg(@game, @msg) {
    foreach(@player: @data in @game['players']) {
        if(ponline(@player)) {
            action_msg(@player, @msg);
        }
    }
}

proc _hazards_are_players_alive(@game) {
    foreach(@player: @data in @game['players']) {
        if(pmode(@player) == 'ADVENTURE') {
            return(true);
        }
    }
    return(false);
}

proc _hazards_did_player_win(@game) {
    foreach(@player: @data in @game['players']) {
        if(@data['score'] >= @game['targetScore']) {
            return(true);
        }
    }
    return(false);
}

proc _hazards_get_winner(@game) {
    @highestScore = 0;
    @winner = '';
    foreach(@player: @data in @game['players']) {
        if(ponline(@player) && @data['score'] >= @highestScore) {
            @highestScore = @data['score'];
            @winner = @player;
        }
    }
    return(@winner);
}
