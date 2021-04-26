proc _bind(@pvp) {
	@pvp['binds'][] = bind('player_interact', array(priority: 'HIGH'), array(itemname: 'FIREWORK_ROCKET', button: 'right'), @e, @pvp) {
		if(!array_index_exists(@pvp['players'], player()) || @e['action'] !== 'right_click_block') {
			die();
		}

		consume();
		cancel();
		@loc = location_shift(@e['location'], @e['facing']);
		launch_firework(_center(@loc, 0), array(
			strength: 3,
			flicker: true,
			colors: array('RED'),
			type: 'BURST')
		);
		set_timeout(3000, closure(){
			if(@pvp['players'][player()]['respawn'] == 0) {
				_pvp_msg(@pvp, color('gray').'[PVP] '
					.@pvp['players'][player()]['color'].player().color('r').' rallied his crew!');
				foreach(array_keys(@pvp['players']), @p) {
					if(@p != player()
					&& @pvp['players'][player()]['team'] == @pvp['players'][@p]['team']
					&& pmode(@p) != 'SPECTATOR'
					&& @pvp['players'][@p]['respawn'] == 0) {
						set_ploc(@p, ploc(player()));
					}
				}
			}
		});
	}
}