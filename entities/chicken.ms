/*
	Protection against overcrowding from chicken egg spawning
 */
bind('creature_spawn', null, array(reason: 'EGG'), @event) {
	if(array_size(entities_in_radius(@event['location'], 8)) > 200) {
		cancel();
		spawn_particle(@event['location'], 'SMOKE_NORMAL');
		broadcast(color('gold').'Chicken failed to hatch due to overcrowding.', players_in_radius(@event['location'], 16));
	}
}

/*
	Prevents chickens in chicken jockeys from spawning when mob-spawning is disabled
 */
bind('creature_spawn', null, array(type: 'CHICKEN', reason: 'MOUNT'), @event) {
	@loc = @event['location'];
	if(_is_survival_world(@loc['world']) && array_contains(sk_region_check_flag(@loc, 'deny-spawn'), 'minecraft:zombie')) {
		cancel();
	}
}