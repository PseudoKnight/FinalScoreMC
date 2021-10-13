 bind('player_interact', null, array(itemname: 'NAUTILUS_SHELL', button: 'right'), @event) {
	 if(!pcooldown('NAUTILUS_SHELL')) {
		play_sound(ploc(), array(sound: 'EVENT_RAID_HORN', volume: 512, pitch: 0.5 + rand() * 1.5));
		set_pcooldown('NAUTILUS_SHELL', 60);
	 }
 }