/*
	Grant Uneasy Alliance advancement in non-default worlds
 */
bind('entity_death', null, array(type: 'GHAST'), @event) {
	if(world_info(@event['location']['world'])['environment'] == 'NORMAL'
			&& _is_survival_world(@event['location']['world'])) {
		@damager = '';
		if(array_index_exists(@event['cause'], 'shooter')) {
			@damager = @event['cause']['shooter'];
		} else if(array_index_exists(@event['cause'], 'damager')) {
			@damager = @event['cause']['damager'];
		}
		if(ponline(@damager)) {
			@player = player(@damager);
			runas('~console', "/advancement grant @player only minecraft:nether/uneasy_alliance");
		}
	}
}