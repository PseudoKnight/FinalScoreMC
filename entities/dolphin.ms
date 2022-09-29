/*
	Named dolphin suffocation protection.
	Dolphins can suffocate themselves despite having the correct conditions to breathe.
	Logging this behavior to better figure out how this happens.
 */
bind('entity_damage', null, array(type: 'DOLPHIN', cause: '/(DRYOUT|DROWNING)/'), @event) {
	@name = get_mob_name(@event['id']);
	if(@name) {
		cancel();

		@cause = to_lower(@event['cause']);
		@loc = @event['location'];
		@x = integer(@loc['x']);
		@y = integer(@loc['y']);
		@z = integer(@loc['z']);
		@world = @loc['world'];
		console("@name, a dolphin at @x @y @z (@world), took damage from @cause.");
	}
}