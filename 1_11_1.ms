bind(player_interact, null, array('item': data_values('firework'), 'button': 'right', 'block': 0), @event) {
    @uuid = puuid();
    if(!get_entity_gliding(@uuid)) {
        die();
    }
    @slot = if(@event['hand'] == 'main_hand', null, -106);
    @item = pinv(player(), @slot);
    @length = 20;
    if(@item['meta']) {
        die();
        // for now
        // @length = @item['meta']['firework']['strength'] * 20;
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
    set_pvelocity(player(), _get_vector(pfacing(), 1.7, 0));
    @loc = ploc();
    @loc['y'] += 1;
    play_effect(@loc, 'FIREWORKS_SPARK', associative_array('speed': 0));
    @timer = array(@length);
    @health = pinfo(player(), 5);
    set_interval(50, closure(){
        try {
            if(!get_entity_gliding(@uuid)) {
                if(@timer[0] > @length - 2) {
                    set_entity_gliding(@uuid, true);
                } else {
                    clear_task();
                }
            }
            if(@timer[0] < 1 || pinfo(player(), 5) < @health) {
                clear_task();
            } else {
                @timer[0]--;
                set_pvelocity(player(), _get_vector(pfacing(), 1.7, 0));
                @loc = ploc();
                @loc['y'] += 1;
                play_effect(@loc, 'FIREWORKS_SPARK', associative_array('speed': 0));
            }
        } catch(BadEntityException @ex) {
            clear_task();
        }
    });
}
