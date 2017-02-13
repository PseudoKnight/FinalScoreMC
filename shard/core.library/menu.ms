proc _create_menu() {
    @rules = array(
        array('loot', 1),
        array('keep', 0),
        array('regen', 0),
    );
    @activated = array('name': 'INK_SACK', 'data': 10, 'meta': array('display': color('green').'ACTIVATED'));
    @deactivated = array('name': 'INK_SACK', 'data': 8, 'meta': array('display': color('gray').'DEACTIVATED'));
    create_virtualchest(array(
        'id': 'shard',
        'size': 27,
        'title': 'Rules',
        0: @activated,
        1: @deactivated,
        2: @deactivated,
        9: array(
            'name': 'CHEST', 'meta': array(
                'display': color('aqua').color('bold').'RANDOM LOOT',
                'lore': array(color('white').'Existing chests have randomized loot in them.', color('yellow').'RANDOM, BUT FAIR!'),
            )
        ),
        10: array(
            'name': 'DIAMOND_BLOCK', 'meta': array(
                'display': color('aqua').color('bold').'KEEP INVENTORY',
                'lore': array(color('white').'Players keep their current inventory.', color('red').'VERY UNFAIR!'),
            )
        ),
        11: array(
            'name': 'GOLDEN_APPLE', 'meta': array(
                'display': color('aqua').color('bold').'DISABLE HEALTH REGEN',
                'lore': array(
                    color('white').'Disables health regeneration from hunger satiation.',
                    color('white').'Potions and golden apples still regenerate health.',
                    color('gold').'HARD, BUT FAIR!'
                ),
            )
        ),
        26: array(
            'name': 'DIAMOND_SWORD', 'meta': array(
                'display': color('green').color('bold').'ENTER SHARD',
                'enchants': array(array('elevel': 1, 'etype': 'DURABILITY')),
                'flags': array('HIDE_ENCHANTS')
            )
        ),
    ));
    popen_virtualchest('shard');
    
    bind(inventory_click, array('id': player().'click'), array('player': player()), @event, @rules) {
        if(is_null(pget_virtualchest())) {
            cancel();
            close_pinv();
            die();
        }
        cancel();
        @slot = @event['slot']
        if(@slot == 26) {
            close_pinv();
            include('game.ms');
            _shard_create(@rules);
        } else {
            @item = @event['slotitem'];
            @rule = null;
            try {
                if(array_index_exists(@rules, @slot)) {
                    @rule = @rules[@slot];
                } else if(array_index_exists(@rules, @slot - 9)) {
                    @slot -= 9;
                    @item = @event['inventory'][@slot];
                    @rule = @rules[@slot];
                }
                if(@rule) {
                    if(@rule[1]) {
                        @item['data'] = 8;
                        @item['meta']['display'] = color('gray').'DEACTIVATED';
                        @rule[1] = 0;
                    } else {
                        @item['data'] = 10;
                        @item['meta']['display'] = color('green').'ACTIVATED';
                        @rule[1] = 1;
                    }
                    @inv = array();
                    @inv[@slot] = @item;
                    update_virtualchest('shard', @inv);
                }
            } catch(IndexOverflowException @ex) {
                // probably a negative slot
            }
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
