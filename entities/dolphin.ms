/*
	Named dolphin suffocation protection.
	Dolphins can suffocate themselves despite having the correct conditions to breathe.
 */
bind('entity_damage', null, array(type: 'DOLPHIN', cause: '/(DRYOUT|DROWNING|SUFFOCATION)/'), @event) {
	@name = get_mob_name(@event['id']);
	if(@name) {
		cancel();

		@cause = to_lower(@event['cause']);
		if(@cause != 'drowning') {
			// Drowning seems to be caused by bad pathing or entity collisions,
			// but log other causes to see if we need to keep canceling them.
			@loc = @event['location'];
			@x = integer(@loc['x']);
			@y = integer(@loc['y']);
			@z = integer(@loc['z']);
			@world = @loc['world'];
			console("Debug: Canceled damage from @cause to @name, a dolphin at @x @y @z (@world).", false);
		}
	}
}