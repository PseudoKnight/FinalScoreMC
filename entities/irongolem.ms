# Cancel spawning when player is not near
bind(creature_spawn, null, array('reason': 'VILLAGE_DEFENSE'), @event) {
    proc _chunk_distance(@loc1, @loc2) {
    	return(ceil(max(abs(@loc1[0] - @loc2[0]), abs(@loc1[2] - @loc2[2])) / 16));
    }
    
    @loc = @event['location'];
    @viewdistance = array(8);
	foreach(@p in all_players(@loc['world'])) {
        if(extension_exists('CHPaper')) {
            array_set(@viewdistance, 0, pview_distance(@p));
        }
        if(_chunk_distance(ploc(@p), @loc, false) <= @viewdistance[0]) {
            die();
        }
    }
    cancel();
    unload_chunk(@loc);
}
