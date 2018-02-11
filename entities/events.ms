# Limit breeding in high entity areas
bind(creature_spawn, null, array('reason': 'BREEDING'), @event) {
	if(!array_contains(array('DONKEY', 'HORSE', 'MULE'), @event['type'])
	&& array_size(entities_in_radius(@event['location'], 64)) > 300) {
		cancel();
		play_effect(@event['location'], 'SMOKE', array('id': 4));
		broadcast(color('gold').'Breeding failed due to overcrowding.', players_in_radius(@event['location'], 16));
	}
}

bind(creature_spawn, null, array('reason': 'EGG'), @event) {
	if(array_size(entities_in_radius(@event['location'], 8)) > 200) {
		cancel();
		play_effect(@event['location'], 'SMOKE', array('id': 4));
		broadcast(color('gold').'Chicken failed to hatch due to overcrowding.', players_in_radius(@event['location'], 16));
	}
}

# Block creeper damage on the surface.
bind(entity_explode, null, array('type': 'CREEPER'), @event) {
	if(@event['location']['y'] > 62
	&& array_contains(array('world', 'world3', 'world4', 'omega'), @event['location']['world'])) {
		cancel();
		play_effect(@event['location'], 'EXPLOSION_HUGE');
	}
}

# prevent egg-spawned mobs from despawning
bind(creature_spawn, null, array('reason': 'SPAWNER_EGG'), @event) {
	set_entity_persistence(@event['id'], true);
}

# block skeleton trap horses in regions
bind(creature_spawn, null, array('reason': 'LIGHTNING', 'type': 'SKELETON_HORSE'), @event) {
	if(@event['location']['world'] != 'outworld') {
		cancel();
	}
}

# prevent enderpearls from damaging item frames and paintings
bind(entity_damage, null, array('type': 'ITEM_FRAME', 'cause': 'PROJECTILE'), @event) {
	if(entity_type(@event['damager']) === 'ENDER_PEARL') {
		cancel();
	}
}

// Block firework damage
bind(entity_damage, null, array('cause': 'ENTITY_EXPLOSION'), @event) {
	if(entity_type(@event['damager']) == 'FIREWORK') {
		cancel();
	}
}

// Always drop full enderdragon experience
bind(entity_death, null, array('type': 'ENDER_DRAGON'), @event) {
	if(@event['xp'] < 12000) {
		modify_event('xp', 12000);
		@loc = get_highest_block_at(0, 0, @event['location']['world']);
		@loc['y'] += 1;
		set_block_at(@loc, data_values('enderdragon_egg'));
	}
}

// Block ghast fireball damage to all but natural nether blocks
bind(entity_explode, null, array('type': 'FIREBALL'), @event) {
	@world = @event['location']['world'];
	if(world_info(@world)['environment'] == 'NETHER' && @world != 'outworld_nether') {
		@blocks = @event['blocks'];
		@breakables = array('87:0', '88:0', '13:0', '213:0', '89:0', '153:0');
		@modify = false;
		foreach(@index: @block in @blocks) {
			if(!array_contains(@breakables, get_block_at(@block))) {
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
bind(creature_spawn, null, array('type': 'CHICKEN', 'reason': 'MOUNT'), @event) {
	@loc = @event['location'];
	if(_is_survival_world(@loc['world']) && array_contains(sk_region_check_flag(@loc, 'deny-spawn'), 'zombie')) {
		cancel();
	}
}
