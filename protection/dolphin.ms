/*
	Named dolphin suffocation protection.
	Dolphins can suffocate themselves despite having the correct conditions to breathe.
 */
bind('entity_damage', null, array(type: 'DOLPHIN', cause: '/(DRYOUT|DROWNING|FALL)/'), @event) {
	@name = get_mob_name(@event['id']);
	if(@name) {
		cancel();
	}
}