switch(@action) {
case 'load':
	bind('player_interact', array(id: @player.'blind'), array(player: @player, itemname: 'WOODEN_HOE', button: 'right'), @event, @pvp) {
		if(pinfo(player(), 6) != @event['item']['name']) {
			die();
		}
		if(pcooldown('WOODEN_HOE')) {
			die();
		}
		foreach(@player in players_in_radius(ploc(), 18)) {
			if(@player != player() && pmode(@player) != 'SPECTATOR'
			&& (!array_index_exists(@pvp, 'teams') || @pvp['players'][player()]['team'] != @pvp['players'][@player]['team'])) {
				set_peffect(@player, 'BLINDNESS', 0, 7);
				@cloud = spawn_entity('AREA_EFFECT_CLOUD', 1, ploc(@player), closure(@cloud) {
					set_entity_spec(@cloud, array(particle: 'SMOKE_LARGE', radius: 1, duration: 7000 / 50));
				})[0];
				set_entity_rider(puuid(@player), @cloud);
			}
		}
		play_sound(ploc(), array(sound: 'ENTITY_SKELETON_HORSE_DEATH', pitch: 0.5, volume: 2));
		@slot = pheld_slot();
		@item = pinv(player(), @slot);
		@item['meta']['enchants'] = array();
		set_pinv(player(), @slot, @item);
		set_pcooldown('WOODEN_HOE', 15000 / 50);
		set_timeout(15000, closure(){
			if(ponline(player())) {
				@item = pinv(player(), @slot);
				if(@item && @item['name'] == 'WOODEN_HOE') {
					play_sound(ploc(), array(sound: 'BLOCK_ENCHANTMENT_TABLE_USE'));
					@item['meta']['enchants']['sharpness'] = 1;
					set_pinv(player(), @slot, @item);
				}
			}
		});
	}

case 'unload':
	unbind(@player.'blind');

}
