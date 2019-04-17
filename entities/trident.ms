bind('projectile_hit', null, array('type': 'TRIDENT'), @event) {
    set_timeout(200, closure() {
        @eloc = entity_loc(@event['shooter']);
        @loc = @event['location'];
        @loc['yaw'] = get_yaw(@loc, @eloc);
        @loc['pitch'] = get_pitch(@loc, @eloc);
        @vector = get_vector(@loc, 0.5);
        try(set_entity_velocity(@event['id'], @vector));
    });
}
