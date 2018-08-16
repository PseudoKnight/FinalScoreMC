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

	// Check mumble user count
	@previousCount = import('mumbleCount');
	x_new_thread('mumbleQuery', closure(){
		@ip = '192.227.136.164';
		@port = 64758;
		@count = @previousCount;
		try {
			@count = mumble_count(@ip, @port);
		} catch(Exception @ex) {
			die();
		}
		if(@count != @previousCount) {
			@type = 'people';
			if(@count == 1) {
				@type = 'person';
			}
			@msg = colorize("&oCurrently &a&o@count&r&o @type on Mumble &7(@ip:@port)");
			x_run_on_main_thread_later(closure(){
				export('mumbleCount', @count);
				if(@count != 0) {
					broadcast(@msg);
					if(extension_exists('CHDiscord')) {
						discord_broadcast(@msg);
					}
				}
			});
		}
	});
});

bind('server_ping', null, null, @event) {
	@activities = import('activities');
	@currently = '';
	if(@activities) {
		@currently = array_implode(array_normalize(@activities), ', ');
	}
	@motd = colorize('&6&l\u1260&d&l\u1260&b&l\u1260&4&l\u1260 &6&lFINALSCORE&e&lMC \u00AB &f\u25AA \u25AA \u25AA');
	modify_event('motd', @motd.if(@currently, colorize('\n&aActivities&f: ').@currently));
}

if(extension_exists('CHDiscord')) {
	bind('discord_voice_joined', null, null, @event) {
		broadcast(@event['nickname'].' joined the "'.@event['channel'].'" Discord voice channel.');
	}
}
