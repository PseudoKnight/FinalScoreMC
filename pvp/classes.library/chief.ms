switch(@action) {
case 'load':
	@uuid = puuid(@player);
	@pvp['players'][@player]['task'] = set_interval(50, closure(){
		try {
			if(!entity_grounded(@uuid)) {
				set_entity_fall_distance(@uuid, -2);
				if(entity_velocity(@uuid)['magnitude'] < 0.51) {
					@strength = -1;
					foreach(@effect in get_peffect(@player)) {
						if(@effect['id'] == 25) {
							@strength = @effect['strength'] - 1;
							break();
						}
					}
					set_peffect(@player, 25, max(-11, @strength), 0.10, true);
				}
			} else {
				set_peffect(@player, 25, 0, 0);
			}
		} catch(Exception @ex) {
			clear_task();
		}
	});
	bind(player_jump, array('id': @player.'moonjump'), array('player': @player), @event) {
		set_peffect(player(), 25, 6, 0.10, true);
	}
	
case 'powerup':
	@item1 = pinv(@player, 0);
	@item2 = pinv(@player, 1);
	if(@item1) {
		set_pcooldown(@player, @item1['name'], 0);
	}
	if(@item2) {
		set_pcooldown(@player, @item2['name'], 0);
	}
	
case 'unload':
	unbind(@player.'moonjump');
	clear_task(@pvp['players'][@player]['task']);
}
