# Cancel spawning when player is not near
bind(creature_spawn, null, array('reason': 'VILLAGE_DEFENSE'), @event) {
    proc _chunk_distance(@loc1, @loc2) {
    	return(ceil(max(abs(@loc1[0] - @loc2[0]), abs(@loc1[2] - @loc2[2])) / 16));
    }
    
    @loc = @event['location'];
	foreach(@p in all_players(@loc['world'])) {
        if(_chunk_distance(ploc(@p), @loc, false) <= pview_distance(@p)) {
            die();
        }
    }
    cancel();
    unload_chunk(@loc);
}
