// cancel llama spit damage on named mobs
bind('entity_damage', null, array(cause: 'PROJECTILE'), @event) {
	if(@event['damagertype'] === 'LLAMA_SPIT'
	&& is_entity_living(@event['id'])
	&& get_mob_name(@event['id'])) {
		cancel();
	}
}