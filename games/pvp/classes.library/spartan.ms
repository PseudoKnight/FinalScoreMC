switch(@action) {
case 'load':
	@uuid = puuid(@player);
	@pvp['players'][@player]['task'] = set_interval(50, closure(){
		try {
			if(!entity_grounded(@uuid)) {
				set_entity_fall_distance(@uuid, -5);
				@v = entity_velocity(@uuid);
				if(@v['magnitude'] < 0.5) {
					@strength = if(@v['y'] > 0, 0, -3);
					@effects = get_peffect(@player);
					if(array_index_exists(@effects, 'levitation')) {
						@strength = @effects['levitation']['strength'] - 1;
					}
					set_peffect(@player, 'LEVITATION', max(-12, @strength), 0.15, true);
				}
			} else {
				set_peffect(@player, 'LEVITATION', 0, 0);
			}
		} catch(Exception @ex) {
			clear_task();
			console(@ex);
		}
	});
	
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
	clear_task(@pvp['players'][@player]['task']);
}
