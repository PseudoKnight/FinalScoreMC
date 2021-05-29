proc _bind(@pvp) {
	@pvp['binds'][] = bind('projectile_hit', null, array(type: 'ARROW'), @e) {
		if(!_is_survival_world(@e['location']['world']) && is_array(@e['shooter'])) {
			entity_remove(@e['id']);
		}
	}
}