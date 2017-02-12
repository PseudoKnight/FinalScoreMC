proc _random_spawn_location(@retry = true) {
    @worldborder = get_world_border('shard');
    @width = @worldborder['width'];
    @loc = @worldborder['center'];
    @loc['x'] += rand() * @width - @width / 2;
    @loc['z'] += rand() * @width - @width / 2;
    @loc = get_highest_block_at(@loc);
    if(get_block_at(@loc) == '9:0' && @retry) {
        return(_random_spawn_location(false));
    }
    return(get_highest_block_at(@loc));
}
