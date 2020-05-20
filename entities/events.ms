# 100% drop rate for all explosions, unless overriden
bind('entity_explode', array('priority': 'HIGH'), null, @event) {
	if(@event['type'] != 'ENDER_DRAGON') {
		modify_event('yield', 1.0);
	}
}

# Limit breeding in high entity areas
bind('creature_spawn', null, array('reason': 'BREEDING'), @event) {
	if(!array_contains(array('DONKEY', 'HORSE', 'MULE'), @event['type'])
	&& array_size(entities_in_radius(@event['location'], 48)) > 300) {
		cancel();
		spawn_particle(@event['location'], 'SMOKE_NORMAL');
		broadcast(color('gold').'Breeding failed due to overcrowding.', players_in_radius(@event['location'], 16));
	}
}

bind('creature_spawn', null, array('reason': 'EGG'), @event) {
	if(array_size(entities_in_radius(@event['location'], 8)) > 200) {
		cancel();
		spawn_particle(@event['location'], 'SMOKE_NORMAL');
		broadcast(color('gold').'Chicken failed to hatch due to overcrowding.', players_in_radius(@event['location'], 16));
	}
}

# Block creeper damage on the surface.
bind('entity_explode', null, array('type': 'CREEPER'), @event, @worlds = array('world', 'world3', 'world4', 'omega', 'psi')) {
	if(array_contains(@worlds, @event['location']['world'])) {
		cancel();
		spawn_particle(@event['location'], 'EXPLOSION_HUGE');
	}
}

# prevent egg-spawned mobs from despawning
bind('creature_spawn', null, array('reason': 'SPAWNER_EGG'), @event) {
	set_entity_persistence(@event['id'], true);
}

# block skeleton trap horses in regions
bind('creature_spawn', null, array('reason': 'LIGHTNING', 'type': 'SKELETON_HORSE'), @event) {
	if(@event['location']['world'] != 'outworld' && sk_regions_at(@event['location'])) {
		cancel();
	}
}

# prevent enderpearls from damaging item frames and paintings
bind('entity_damage', null, array('type': 'ITEM_FRAME', 'cause': 'PROJECTILE'), @event) {
	if(entity_type(@event['damager']) === 'ENDER_PEARL') {
		cancel();
	}
}

// Block firework damage
bind('entity_damage', null, array('cause': 'ENTITY_EXPLOSION'), @event) {
	if(entity_type(@event['damager']) == 'FIREWORK') {
		// Crossbows currently do not set the firework's shooter.
		// This is an imperfect solution but captures more cases where we want to cancel damage.
		if(!is_null(get_firework_shooter(@event['damager']))) {
			cancel();
		} else if(!entity_exists(@event['id'])) {
			// what the hell is going on?
			if(array_index_exists(@event, 'player')) {
				if(_is_survival_world(@event['world'])) {
					// ensure we disabled pvp in survival
					cancel();
				}
			} else {
				console('Entity doesn\'t exist in entity_damage event: '.@event['type']);
			}
		} else if(is_tameable(@event['id']) && get_mob_owner(@event['id']) != null) {
			cancel();
		} else {
			@type = entity_type(@event['id']);
			if(@type == 'ITEM_FRAME' || @type == 'ARMOR_STAND' || @type == 'PAINTING'
			|| @type == 'PLAYER' && _is_survival_world(@event['location']['world'])) {
				cancel();
			}
		}
	}
}

// Block ghast fireball damage to all but natural nether blocks
bind('entity_explode', null, array('type': 'FIREBALL'), @event) {
	@world = @event['location']['world'];
	if(_is_survival_world(@world) && @world != 'outworld_nether') {
		@blocks = @event['blocks'];
		@breakables = array('NETHERRACK', 'SOUL_SAND', 'GRAVEL', 'MAGMA_BLOCK', 'GLOWSTONE', 'NETHER_QUARTZ_ORE');
		@modify = false;
		foreach(@index: @block in @blocks) {
			if(!array_contains(@breakables, get_block(@block))) {
				array_remove(@blocks, @index);
				@modify = true;
			}
		}
		if(@modify) {
			modify_event('blocks', @blocks);
		}
	}
}

// Prevents chickens in chicken jockeys from spawning when mob-spawning is disabled
bind('creature_spawn', null, array('type': 'CHICKEN', 'reason': 'MOUNT'), @event) {
	@loc = @event['location'];
	if(_is_survival_world(@loc['world']) && array_contains(sk_region_check_flag(@loc, 'deny-spawn'), 'minecraft:zombie')) {
		cancel();
	}
}
