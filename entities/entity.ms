# 100% drop rate for all explosions, unless overriden
bind('entity_explode', array('priority': 'HIGH'), null, @event) {
	if(@event['type'] != 'ENDER_DRAGON') {
		modify_event('yield', 1.0);
	}
}

# Limit breeding in high entity areas
bind('creature_spawn', null, array('reason': 'BREEDING'), @event) {
	if(!array_contains(array('DONKEY', 'HORSE', 'MULE'), @event['type'])
	&& array_size(entities_in_radius(@event['location'], 48)) > 320) {
		cancel();
		spawn_particle(@event['location'], 'SMOKE_NORMAL');
		broadcast(color('gold').'Breeding failed due to overcrowding.', players_in_radius(@event['location'], 16));
	}
}

# Limit dispensing entities
bind('creature_spawn', null, array('reason': 'DISPENSE_EGG'), @event) {
	if(!_is_survival_world(@event['location']['world'])) {
		if(array_size(entities_in_radius(@event['location'], 48)) > 300) {
			cancel();
			spawn_particle(@event['location'], 'SMOKE_NORMAL');
		}
	}
}

# prevent egg-spawned mobs from despawning
bind('creature_spawn', null, array('reason': 'SPAWNER_EGG'), @event) {
	set_entity_persistence(@event['id'], true);
}

# enforce 1.18 light level requirement
bind('creature_spawn', null, array(reason: 'NATURAL'), @event) {
	if(world_info(@event['location']['world'])['environment'] == 'NORMAL' && get_block_light_at(@event['location'])) {
		@lightAffected = array('CREEPER', 'ENDERMAN', 'HUSK', 'SKELETON', 'SPIDER', 'STRAY', 'WITCH', 'ZOMBIE', 'ZOMBIE_VILLAGER');
		if(array_contains(@lightAffected, @event['type'])) {
			cancel();
		}
	}
}