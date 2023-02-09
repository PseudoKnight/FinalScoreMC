/*
	When a trident hits a lodestone, summon a lightning storm.
 */
bind('projectile_launch', null, array(type: 'TRIDENT', shootertype: 'PLAYER'), @event) {
	@item = pinv(player(), null);
	if(@item && @item['meta'] && array_index_exists(@item['meta']['enchants'], 'channeling')) {
		add_scoreboard_tag(@event['id'], 'channeling');
	}
}

bind('projectile_hit', null, array(type: 'TRIDENT'), @event) {
	if(@event['hittype'] == 'BLOCK' && array_contains(get_scoreboard_tags(@event['id']), 'channeling')) {
		@block = get_block(@event['hit']);
		if(@block == 'LODESTONE' && get_highest_block_at(@event['hit'])['y'] == @event['hit']['y']) {
			storm(true, @event['location']['world']);
			set_thunder(true, @event['location']['world']);
			lightning(@event['location']);
		}
	}
	// This animates the trident back to the player better than vanilla,
	// but it does consequently reduce loyalty time.
	// First check if they're in the same world.
	if(entity_exists(@event['shooter']) && entity_type(@event['shooter']) == 'PLAYER'
	&& @event['location']['world'] == ploc(@event['shooter'])['world']) {
		set_timeout(200, closure() {
			if(entity_exists(@event['shooter'])
			&& entity_exists(@event['id'])) {
				@eloc = entity_loc(@event['shooter']);
				@loc = @event['location'];
				@loc['yaw'] = get_yaw(@loc, @eloc);
				@loc['pitch'] = get_pitch(@loc, @eloc);
				if(@loc['yaw'] != NaN) {
					@vector = get_vector(@loc, 0.5);
					set_entity_velocity(@event['id'], @vector);
				}
			}
		});
	}
}
