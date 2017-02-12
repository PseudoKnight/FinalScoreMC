bind(player_interact, null, array('item': 264, 'hand': 'main_hand', 'block': 0), @event) {
    include('core.library/util.ms');
    if(array_contains(get_worlds(), 'shard')) {
        if(pworld() == 'shard') {
            action_msg('You can\'t go deeper!');
        } else {
            // Late join
            play_sound(ploc(), array('sound': 'GLASS', 'pitch': 0.5));
            @loc = get_spawn('shard');
            @loc['y'] -= 1;
            set_ploc(_random_spawn_location());
            @mode = get_metadata('shard', 'mode', 'CommandHelper');
            include('core.library/game.ms');
            include('modes.library/'.@mode.'.ms');
            _shard_equip(player());
            set_peffect(player(), 11, 3, 30, true);
            play_sound(@loc, array('sound': 'GLASS', 'pitch': 0.5), player());
            if(get_world_border('shard')['width'] < 128) {
                set_pmode('SPECTATOR');
            }
        }
        die();
    }
    if(!has_permission('group.moderator')) {
        action_msg('Only staff can generate shards for now!');
        die();
    }
    
    // Open menu
    create_virtualchest(array(
        'id': 'shard',
        'size': 9,
        'title': 'Modes',
        0: array(
            'name': 'CHEST', 'meta': array(
                'display': color('aqua').color('bold').'LOOT',
                'lore': array(color('white').'Inventory gathered from materials or loot chests', color('yellow').'RANDOM, BUT FAIR!'),
            )
        ),
        1: array(
            'name': 'DIAMOND_BLOCK', 'meta': array(
                'display': color('aqua').color('bold').'KEEP',
                'lore': array(color('white').'Keep all survival inventory.', color('red').'VERY UNFAIR!'),
            )
        ),
    ));
    popen_virtualchest('shard');
    
    bind(inventory_click, array('id': player().'click'), array('player': player()), @event) {
        if(is_null(pget_virtualchest())) {
            cancel();
            close_pinv();
            die();
        }
        cancel();
        @mode = strip_colors(_item_meta(@event['slotitem'], 'display'));
        if(@mode) {
            close_pinv();
            include('core.library/game.ms');
            include('modes.library/'.to_lower(@mode).'.ms');
            _shard_create(@mode);
        }
    }
    
    bind(inventory_close, array('id': player().'open'), null, @event, @player = player()) {
        if(player() == @player) {
            unbind();
            unbind(player().'click');
            del_virtualchest('shard');
        }
    }
}
