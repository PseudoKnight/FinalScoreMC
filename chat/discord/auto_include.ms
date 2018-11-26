/*
	Updates the channel topic for the discord chat channel
*/
proc _update_discord_topic() {
	@activities = '';
	@activitiesArray = import('activities');
	if(@activitiesArray) {
		@activities = array_implode(array_normalize(@activitiesArray), ', ');
	}
	@allocMem = get_server_info(15);
	@freeMem = get_server_info(16);
	if(extension_exists('CHDiscord')) {
		discord_set_channel_topic('minecraft_chat', '---[ FinalScoreMC Server ]---[ TPS: '.round(tps()[0], 1).' ]'
			.'---[ Memory: '.floor((@allocMem - @freeMem) / 1000000).' MB / 3 GB ]'
			.'---[ Players: '.array_size(all_players()).' ]'
			.'---'.if(@activities, '[ Activities: '.@activities.' ]---')
		);
	}
}
