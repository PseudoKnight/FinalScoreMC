bind('item_swap', null, array(main_hand: 'LIGHTNING_ROD'), @event) {
	if(pmode() !== 'ADVENTURE') {
		die();
	}
	cancel();
	if(pcooldown('LIGHTNING_ROD')) {
		die();
	}
	set_pcooldown('LIGHTNING_ROD', 3);
	@item = @event['main_hand'];
	if(@item['meta'] && @item['meta']['model'] > 0) {
		play_sound(ploc(), array(sound: 'BLOCK_COPPER_BULB_TURN_OFF', pitch: 2));
		play_sound(ploc(), array(sound: 'ENTITY_CHICKEN_STEP', pitch: 0.5, seed: 1));
		@item['meta']['model'] = 0;
		set_pinv(player(), -106, @item);
	} else {
		play_sound(ploc(), array(sound: 'BLOCK_COPPER_BULB_TURN_ON', pitch: 2));
		play_sound(ploc(), array(sound: 'ENTITY_CHICKEN_STEP', pitch: 0.5, seed: 1));
		if(!@item['meta'] || !array_index_exists(@item['meta'], 'maxdamage')) {
			@item['meta'] = array(display: color('white').'Flash Light', model: 1, maxdamage: 2048, damage: 1);
		} else {
			@item['meta']['model'] = 1;
		}
		set_pinv(player(), -106, @item);
		@blocks = array();
		set_interval(50, closure(){
			foreach(@index: @block in @blocks) {
				if(get_block(@block) === 'LIGHT') {
					set_block(@block, 'AIR');
				}
				array_remove(@blocks, @index);
			}
			@item = pinv(player(), -106);
			if(!@item || @item['name'] !== 'LIGHTNING_ROD' || !@item['meta'] || @item['meta']['model'] < 1 || @item['meta']['damage'] >= @item['meta']['maxdamage']) {
				if(@item && @item['name'] === 'LIGHTNING_ROD' && @item['meta'] && @item['meta']['model'] > 0) {
					play_sound(ploc(), array(sound: 'BLOCK_COPPER_BULB_TURN_OFF', pitch: 2));
					play_sound(ploc(), array(sound: 'ENTITY_CHICKEN_STEP', pitch: 0.5, seed: 1));
					@item['meta']['model'] = 0;
					set_pinv(player(), -106, @item);
				}
				clear_task();
				die();
			}
			@item['meta']['damage']++;
			set_pinv(player(), -106, @item);
			@level = 7;
			if(@item['meta']['maxdamage'] - @item['meta']['damage'] < 100 && rand(2)) {
				@level = 5
			}

			@line = entity_line_of_sight(puuid(), array('AIR'), @level + 3);
			for(@i = 0, @i < array_size(@line), @i++) {
				@block = @line[@i];
				if(get_block(@block) === 'AIR') {
					set_blockdata(@block, array(block: 'light', level: if(@i >= array_size(@line) - 2, @level + 3, min(@level, @i + @level - 4))));
					@blocks[] = @block;
				}
			}
			if(!@blocks) {
				@block = entity_loc(puuid());
				if(get_block(@block) === 'AIR') {
					set_blockdata(@block, array(block: 'light', level: @level));
					@blocks[] = @block;
				} else {
					play_sound(ploc(), array(sound: 'BLOCK_COPPER_BULB_TURN_OFF', pitch: 2));
					play_sound(ploc(), array(sound: 'ENTITY_CHICKEN_STEP', pitch: 0.5, seed: 1));
					@item['meta']['model'] = 0;
					set_pinv(player(), -106, @item);
				}
			}
		});
	}
}