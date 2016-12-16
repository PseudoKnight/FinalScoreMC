bind(player_interact, null, array('item': data_values('firework'), 'button': 'right', 'block': 0), @event) {
    @uuid = puuid();
    if(!get_entity_gliding(@uuid)) {
        die();
    }
    @slot = if(@event['hand'] == 'main_hand', null, -106);
    @item = pinv(player(), @slot);
    @length = 20;
    if(@item['meta']) {
        if(@item['meta']['firework']['effects']) {
            die();
        }
        @length = @item['meta']['firework']['strength'] * 20;
    }
    if(@item['qty'] > 1) {
        @item['qty']--;
    } else {
        @item = null;
    }
    @inv = associative_array();
    @inv[@slot] = @item;
    set_pinv(@inv);
    play_sound(ploc(), associative_array('sound': 'FIREWORK_LAUNCH', 'volume': 3));
    @timer = array(@length);
    @health = pinfo(player(), 5);
    @boost = closure(@interval = true){
        try {
            if(!get_entity_gliding(@uuid)) {
                if(@timer[0] > @length - 3) {
                    set_entity_gliding(@uuid, true);
                } else if(@interval) {
                    clear_task();
                }
            }
            if(@interval && (@timer[0] < 1 || pinfo(player(), 5) < @health)) {
                clear_task();
            } else {
                @timer[0]--;
                @v1 = entity_velocity(@uuid);
                @v2 = _get_vector(pfacing(), 1, 0);
                @v1['x'] += @v2['x'] * 0.1 + (@v2['x'] * 1.5 - @v1['x']) * 0.5;
                @v1['y'] += @v2['y'] * 0.1 + (@v2['y'] * 1.5 - @v1['y']) * 0.5;
                @v1['z'] += @v2['z'] * 0.1 + (@v2['z'] * 1.5 - @v1['z']) * 0.5;
                set_entity_velocity(@uuid, @v1);
                @loc = ploc();
                @loc['y'] += 1;
                play_effect(@loc, 'FIREWORKS_SPARK', associative_array('speed': 0));
            }
        } catch(BadEntityException @ex) {
            if(@interval) {
                clear_task();
            }
        }
    }
    execute(false, @boost);
    set_interval(50, @boost);
}
