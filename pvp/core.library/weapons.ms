proc _weapon_cooldown(@player, @time, @type, @onCooldown, @remove = 1) {
	switch(@type) {
		case 'damage':
			#TODO: weapon damage
			null;
			
		default:
			@item = pinv(@player, null);
			@item['qty'] -= @remove;
			if(@item['qty'] == 0) {
				set_pinv(@player, array('null': null));
			} else {
				@newItem = @item[];
				@newItem['name'] = @type;
				@newItem['data'] = 0;
				set_pinv(@player, array('null': @newItem));
				@slot = pinfo(@player, 15);
				set_timeout(@time, closure(){
					@newItem = pinv(@player, @slot);
					if(!is_null(@newItem) 
					&& @newItem['name'] == @type) {
						@inv = array();
						@inv[@slot] = @item;
						set_pinv(@player, @inv);
						if(@onCooldown) {
							execute(@onCooldown);
						}
					}
				})
			}
	}
}