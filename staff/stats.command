register_command('stats', array(
	description: 'Lists players by the number of completed advancements or other stats.',
	usage: '/stats [advancements|recipes]',
	permission: 'command.stats',
	tabcompleter: _create_tabcompleter(array('advancements', 'recipes')),
	executor: closure(@alias, @sender, @args, @info) {
		@type = array_get(@args, 0, 'advancements');
		@total = 0;
		if(@type === 'advancements') {
			@total = 122; // 1.21.3
		} else if(@type === 'recipes') {
			@total = 1337; // 1.21.3
		} else {
			return(false);
		}
		x_new_thread('StatsCommand', closure(){
			// read files, parse, collect and sort data on separate thread
			@top = array();
			@dir = sys_properties('user.dir');
			foreach(@file in list_files(@dir.'/worlds/world/advancements/')) {
				@advancements = json_decode(read(@dir.'/worlds/world/advancements/'.@file));
				@count = 0;
				foreach(@key: @adv in @advancements) {
					if(is_array(@adv)
					&& (@type === 'recipes' && string_starts_with(@key, 'minecraft:recipes')
					|| @type === 'advancements' && !string_starts_with(@key, 'minecraft:recipes'))) {
						if(@adv['done']) {
							@count++;
						}
					}
				}
				// only add players with at least half of the total
				if(@count >= @total / 2) {
					@top[] = array(
						uuid: replace(split('.', @file)[0], '-', ''),
						count: @count,
					);
				}
			}
			// sort highest to lowest
			array_sort(@top, closure(@left, @right) {
				return(@left['count'] < @right['count']);
			});
			x_run_on_main_thread_later(closure(){
				// go back to main thread for pdata
				@i = 0;
				@previousCount = @total;
				@tiedCount = 0;
				msg("Total @type: @total");
				foreach(@t in @top) {
					@i++;
					@uuid = @t['uuid'];
					@count = @t['count'];
					@place = @i;
					// check for ties with previous counts
					if(@previousCount <= @t['count']) {
						@tiedCount++;
						@place = @i - @tiedCount;
					} else {
						@tiedCount = 0;
					}
					@name = _pdata_by_uuid(@uuid)['name'];
					msg("[@place] @name: @count");
					if(@i >= 19) { // 20 lines are visible in chat
						break();
					}
					@previousCount = @t['count'];
				}
			});
		});
	}
));