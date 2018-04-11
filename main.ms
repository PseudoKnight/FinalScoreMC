set_cron('*/5 * * * *', closure(){
	foreach(@world in get_worlds()) {
		queue_push(closure(){
			save_world(@world);
		});
	}
	queue_push(closure(){
		save_players();
		@activities = '';
		@activitiesArray = import('activities');
		if(@activitiesArray) {
			@activities = array_implode(array_normalize(@activitiesArray), ', ');
		}
		@allocMem = get_server_info(15);
		@freeMem = get_server_info(16);
		console('---[ SAVED ]---[ TPS: '.round(tps()[0], 1).' ]'
			.'---[ MEM: '.floor((@allocMem - @freeMem) / 1000000).' / '.floor(@allocMem / 1000000).' / 2863 MB ]'
			.'---[ PLAYERS: '.array_size(all_players()).' ]'
			.'---'.if(@activities, '[ Activities: '.@activities.' ]---'), false);
	});
})

bind(server_ping, null, null, @event) {
	@activities = import('activities');
	@currently = '';
	if(@activities) {
		@currently = array_implode(array_normalize(@activities), ', ');
	}
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	modify_event('motd', @motd.if(@currently, colorize('\n&aActivities&f: ').@currently));
}

if(extension_exists('CHDiscord')) {
	bind(discord_voice_joined, null, null, @event) {
		broadcast(@event['nickname'].' joined the "'.@event['channel'].'" Discord voice channel.');
	}
}
