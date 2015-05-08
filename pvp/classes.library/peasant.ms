switch(@action) {
case 'load':
	bind(entity_damage, array('id': @player.'poisonpotato'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e,
			@p = @player) {
		if(@e['damager'] == @p) {
			@item = pinv(@p, null);
			if(!is_null(@item) && @item['type'] == 394) {
				set_peffect(@e['player'], 19, 0, 10);
			}
		}
	}
	
	bind(entity_damage, array('id': @player.'potato'), array('type': 'PLAYER', 'cause': 'ENTITY_ATTACK', 'world': 'custom'), @e,
			@p = @player) {
		if(@e['damager'] == @p) {
			@item = pinv(@p, null);
			if(!is_null(@item) && @item['type'] == 392) {
				modify_event('amount', 3);
				set_timeout(50, closure(){
					set_pvelocity(@e['player'], rand(2), 1, rand(2));
				});
			}
		}
	}
	
case 'unload':
	unbind(@player.'poisonpotato');
	unbind(@player.'potato');
}