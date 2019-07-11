switch(@action) {
case 'load':
	bind('player_toggle_sneak', array('id': @player.'huntersneaking'), array('player': @player), @event) {
		@item = pinv(player(), 0);
		if(@event['sneaking']) {
			@item['meta']['enchants']['multishot'] = 1;
			@item['meta']['enchants']['piercing'] = 0;
		} else {
			@item['meta']['enchants']['multishot'] = 0;
			@item['meta']['enchants']['piercing'] = 4;
		}
		set_pinv(player(), 0, @item);
	}

	@arrows = array();

	bind('projectile_launch', array('id': @player.'huntershoot'), array('type': 'ARROW', 'shootertype': 'PLAYER'), @event, @player, @arrows) {
		if(@event['player'] == @player) {
			@arrows[@event['id']] = time();
			set_arrow_damage(@event['id'], 0.8);
		}
	}

	bind('projectile_hit', array('id': @player.'hunterhit'), array('type': 'ARROW'), @event, @pvp, @uuid = puuid(@player), @player, @arrows) {
		if(@uuid == @event['shooter']) {
			if(@event['hittype'] == 'ENTITY') {
				if(ponline(@event['hit'])) {
					@arrowTime = 0;
					foreach(@arrow: @time in @arrows) {
						if(@event['id'] == @arrow) {
							@arrowTime = @time;
							array_remove(@arrows, @arrow);
						} else if(time() - @time > 5000) { // remove old arrows
							array_remove(@arrows, @arrow);
						}
					}
					if(@arrowTime != 0) { // hit with valid arrow
						foreach(@arrow: @time in @arrows) {
							if(abs(@arrowTime - @time) < 50) { // test for multi-shot arrows
								array_remove(@arrows, @arrow);
							}
						}
						@item = pinv(@player, 0);
						if(!array_index_exists(@item['meta']['enchants'], 'quick_charge')) {
							@item['meta']['enchants']['quick_charge'] = 1;
							set_pinv(@player, 0, @item);
						} else if(@item['meta']['enchants']['quick_charge']['elevel'] < 5) {
							@item['meta']['enchants']['quick_charge']['elevel']++;
							set_pinv(@player, 0, @item);
						}
					}
				}
			} else {
				foreach(@arrow: @time in @arrows) {
					if(@event['id'] == @arrow) {
						@item = pinv(@player, 0);
						if(array_index_exists(@item['meta']['enchants'], 'quick_charge')) {
							array_remove(@item['meta']['enchants'], 'quick_charge');
							set_pinv(@player, 0, @item);
						}
						break();
					}
				}
			}
		}
	}

case 'unload':
	unbind(@player.'huntersneaking');
	unbind(@player.'huntershoot');
	unbind(@player.'hunterhit');

}
