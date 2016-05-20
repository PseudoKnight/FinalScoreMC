proc _snake_valid_location(@region, @padding = 0) {
    @i = 0;
    while(@i < 20) {
        @i++;
        @coords = sk_region_info(@region, 'custom')[0];
        @x = 0;
        @y = 0;
        @z = 0;
        if(@padding == 0 || @coords[1][0] == @coords[0][0]) {
            @x = @coords[1][0] + rand(1 + @coords[0][0] - @coords[1][0]);
        } else {
            @x = (@coords[1][0] + @padding) + rand(1 + @coords[0][0] - @coords[1][0] - (@padding * 2));
        }
        if(@padding == 0 || @coords[1][1] == @coords[0][1]) {
            @y = @coords[1][1] + rand(1 + @coords[0][1] - @coords[1][1]);
        } else {
            @y = (@coords[1][1] + @padding) + rand(1 + @coords[0][1] - @coords[1][1] - (@padding * 2));
        }
        if(@padding == 0 || @coords[1][2] == @coords[0][2]) {
            @z = @coords[1][2] + rand(1 + @coords[0][2] - @coords[1][2]);
        } else {
            @z = (@coords[1][2] + @padding) + rand(1 + @coords[0][2] - @coords[1][2] - (@padding * 2));
        }
        if(get_block_at(@x, @y, @z, 'custom') == '0:0') {
            return(array(@x, @y, @z, 'custom'));
        }
    }
    return(null);
}

proc _snake_direction_of(@loc, @block, @not) {
    foreach(@dir in array('down', 'up', 'north', 'south', 'east', 'west')) {
        if((!@not || @not != @dir) && get_block_at(_relative(@loc, @dir)) == @block) {
            return(@dir);
        }
    }
    return(null);
}

proc _snake_safe_block(@loc) {
    @id = split(':', get_block_at(@loc))[0];
    if(@id == '159' || @id == '155' || @id == '88') {
        return(false);
    }
    return(true);
}

proc _snake_opposite_dir(@dir) {
    switch(@dir) {
        case 'up':
            return('down');
        case 'down':
            return('up');
        case 'north':
            return('south');
        case 'south':
            return('north');
        case 'east':
            return('west');
        case 'west':
            return('east');
    }
    return(null);
}

proc _snake_farthest_dir(@loc1, @loc2) {
    @x = @loc1[0] - @loc2[0];
    @y = @loc1[1] - @loc2[1];
    @z = @loc1[2] - @loc2[2];
    @ax = abs(@x);
    @ay = abs(@y);
    @az = abs(@z);
    if(@ax > @ay && @ax > @az) {
        if(@x > 0) {
            return('west');
        } else if(@x < 0) {
            return('east');
        }
    } else if(@az > @ax && @az > @ay) {
        if(@z > 0) {
            return('north');
        } else if(@z < 0) {
            return('south');
        }
    } else {
        if(@y > 0) {
            return('down');
        } else if(@y < 0) {
            return('up');
        }
    }
    return(null);
}

proc _snake_change_speed(@value, @game) {
    @speeds = array('slow', 'normal', 'fast', 'superfast');
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
