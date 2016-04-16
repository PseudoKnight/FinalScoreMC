proc _snake_valid_location(@region) {
    @i = 0;
    while(@i < 20) {
        @i++;
        @coords = sk_region_info(@region, 'custom')[0];
        @x = @coords[1][0] + rand(1 + @coords[0][0] - @coords[1][0]);
        @y = @coords[1][1] + rand(1 + @coords[0][1] - @coords[1][1]);
        @z = @coords[1][2] + rand(1 + @coords[0][2] - @coords[1][2]);
        if(get_block_at(@x, @y, @z, 'custom') == '0:0') {
            return(array(@x, @y, @z, 'custom'));
        }
    }
    return(null);
}

proc _snake_direction_of(@loc, @block) {
    foreach(@dir in array('up', 'down', 'north', 'south', 'east', 'west')) {
        if(get_block_at(_relative(@loc, @dir)) == @block) {
            return(@dir);
        }
    }
    return(null);
}

proc _snake_block(@id, @loc) {
    if(@id == '170') {
        @dir = _snake_direction_of(@loc, '166:0');
        switch(@dir) {
            case 'east':
            case 'west':
                return(@id.':4');
            case 'north':
            case 'south':
                return(@id.':8');
        }
    }
    return(@id.':0');
}

proc _snake_change_speed(@value, @game) {
    @speeds = array('slow', 'normal', 'fast', 'superfast', 'impossible');
    @current = array_index(@speeds, @game['speed']);
    @new = @current + @value;
    if(@new > -1 && array_index_exists(@speeds, @new)) {
        @game['speed'] = @speeds[@new];
        clear_task(@game['interval']);
        _snake_start_task(@game);
        return(true);
    }
    return(false);
}

proc _snake_play_song() {
    @loc = sk_region_info('snake', 'custom', 0)[1];
    @loc[0] += 20;
    @loc[1] += 15;
    @loc[2] += 20;
    play_effect(@loc, 'RECORD_PLAY', array('id': rand(2257, 2266), 'radius': 32));
}

proc _snake_stop_song() {
    @loc = sk_region_info('snake', 'custom', 0)[1];
    @loc[0] += 20;
    @loc[1] += 15;
    @loc[2] += 20;
    play_effect(@loc, 'RECORD_PLAY', array('id': 0, 'radius': 32));
}
