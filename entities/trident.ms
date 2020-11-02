bind('projectile_launch', null, array('type': 'TRIDENT', 'shootertype': 'PLAYER'), @event) {
    @item = pinv(player(), null);
    if(@item['meta'] && array_index_exists(@item['meta']['enchants'], 'channeling')) {
        add_scoreboard_tag(@event['id'], 'channeling');
    }
}

bind('projectile_hit', null, array('type': 'TRIDENT'), @event) {
    if(@event['hittype'] == 'BLOCK' && array_contains(get_scoreboard_tags(@event['id']), 'channeling')) {
        @block = get_block(@event['hit']);
        if(@block == 'LODESTONE') {
            storm(true, @event['location']['world']);
            set_thunder(true, @event['location']['world']);
            lightning(@event['location']);
        }
    }
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
