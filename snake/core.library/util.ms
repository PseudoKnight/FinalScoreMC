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
    if(@id == 170) {
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
