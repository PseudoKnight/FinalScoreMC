 bind('player_interact', null, array(itemname: 'NAUTILUS_SHELL', button: 'right'), @event) {
	 if(!pcooldown('NAUTILUS_SHELL')) {
		@num = rand(8);
		play_sound(puuid(), array(sound: 'ITEM_GOAT_HORN_SOUND_'.@num, volume: 512, pitch: 0.5 + rand() * 1.5));
		set_pcooldown('NAUTILUS_SHELL', 60);
	 }
 }