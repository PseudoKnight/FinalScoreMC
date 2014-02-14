@timers = get_value('session.timers')
if(!@timers, @timers = array(), clear_value('session.timers'))
export('timer', @timers)

register_command('timer', array(
	'description': 'Handles time trials for speed runs.',
	'usage': '/timer <start|stop> <id>',
	'permission': 'command.timer',
	'executor': closure(@alias, @sender, @args, @info,
	
		if(array_size(@args) == 3) {
		
			@id = @args[1]
			@player = @args[2]
			
			if(@args[0] == 'start') {
			
				@timers = import('timer')
				if(!@timers) {
					@timers = array()
				}
				
				if(array_index_exists(@timers, @player)) {
					clear_task(@timers[@player][2])
				}
				
				@timers[@player] = array(@id, time())
				@ptime = get_value('times.'.@id, @player)
				if(!@ptime) { 
					@ptime = 0
				} else {
					@ptime = ceil(@ptime)
				}
				
				set_plevel(@player, 0)
				play_sound(ploc(@player), array('sound': 'FIREWORK_BLAST'), @player)
				
				@timers[@player][2] = set_interval(1000, closure(
					if(!ponline(@player) 
					|| !array_contains(sk_current_regions(@player), @id)) {
						@timers = import('timer')
						array_remove(@timers, @player)
						export('timer', @timers)
						clear_task()
						if(ponline(@player) && pworld(@player) == 'custom') {
							set_plevel(@player, 0)
						}
					} else {
						@level = plevel(@player)
						@level++
						set_plevel(@player, @level)
						if(@level + 5 > @ptime && @level < @ptime) {
							play_sound(ploc(@player), array('sound': 'CLICK', 'pitch': 2), @player)
						} else if(@level == @ptime) {
							play_sound(ploc(@player), array('sound': 'VILLAGER_NO'), @player)
						}
					}
				))
				
				export('timer', @timers)
			
			} else if(@args[0] == 'stop') {
				
				@timers = import('timer')
				if(array_index_exists(@timers, @player)
				&& @timers[@player][0] == @id) {
					@time = round((time() - @timers[@player][1]) / 1000, 1)
					clear_task(@timers[@player][2])
					array_remove(@timers, @player)
					export('timer', @timers)
					play_sound(ploc(@player), array('sound': 'ORB_PICKUP'), @player)
					
					tmsg(@player, 'You achieved a time of '.color('bold').@time.color('r').' seconds.')
					console(@player.' achieved a time of '.@time.' at '.@id)

					# PERSONAL TIME
					@ptime = get_value('times.'.@id, @player)
					if(!@ptime || @time < @ptime) {
						if(@ptime) {
							tmsg(@player, 'You beat your personal best time of '.color('bold').@ptime.color('r').' seconds.')
						}
						@loc = ploc(@player)
						@loc['y'] += 3
						store_value('times.'.@id, @player, @time)
						
						# TOP TIMES
						@toptimes = get_value('times', @id)
						if(!@toptimes) {
							@toptimes = array(array(@player, @time))
							store_value('times', @id, @toptimes)					
						} else {
							@top = false
							for(@i = 0, @i < 10, @i++) {
								if(!@top) {
									if(!array_index_exists(@toptimes, @i) || @time < @toptimes[@i][1]) {
										array_insert(@toptimes, array(@player, @time), @i)
										@top = true
									}
								} else {
									if(array_index_exists(@toptimes, @i) && @toptimes[@i][0] == @player) {
										array_remove(@toptimes, @i)
									}
								}
							}
							if(@top) {
								tmsg(@player, 'You got a top ten time for this course!')
								launch_firework(@loc, array(
									'strength': 1,
									'flicker': true,
									'trail': true,
									'colors': array(array(rand(256), rand(256), rand(256))),
									'fade': array(array(rand(256), rand(256), rand(256))),
									'type': 'BALL_LARGE',
								))
								if(array_size(@toptimes) > 10) {
									array_remove(@toptimes, 10)
								}
								store_value('times', @id, @toptimes)
							} else {
								launch_firework(@loc, array(
									'strength': 0,
									'trail': false,
									'colors': array(array(rand(256), rand(256), rand(256))),
									'fade': array(array(rand(256), rand(256), rand(256))),
								))
							}
						}
					}
				}
			}
		}
	))
)