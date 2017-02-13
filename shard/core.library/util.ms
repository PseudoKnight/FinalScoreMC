// Returns a starting location within the world border
proc _get_spawn_location(@retry = true) {
    @worldborder = get_world_border('shard');
    @width = @worldborder['width'];
    @loc = @worldborder['center'];
    @loc['x'] += rand() * @width - @width / 2;
    @loc['z'] += rand() * @width - @width / 2;
    @loc = get_highest_block_at(@loc);
    if(get_block_at(@loc) == '9:0' && @retry) {
        @loc = _get_spawn_location(false);
    }
    return(@loc);
}

// Sets the equipment for the start of the game
proc _shard_equip(@player) {
    _clear_pinv(@player);
}
