bind('player_interact', null, array(itemname: 'GOAT_HORN', button: 'right'), @event) {
	if(!pcooldown('GOAT_HORN')) {
		set_timeout(1, closure(){
			set_pcooldown('GOAT_HORN', 80);
		});
	}
}