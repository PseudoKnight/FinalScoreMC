@timers = get_value('session.timers')
if(!@timers) {
	@timers = array()
} else {
	clear_value('session.timers')
}
export('timer', @timers)

register_command('timer', array(
	'description': 'Handles time trials for speed runs.',
	'usage': '/timer <start|stop> <id>',
	'permission': 'command.timer',
	'executor': closure(@alias, @sender, @args, @info,
	
		if(array_size(@args) == 3) {
		
			@id = @args[1]
			@player = @args[2]
			
			if(pmode(@player) != 'CREATIVE') {

				@timers = import('timer')
				
				if(@args[0] == 'start') {
					
					if(array_index_exists(@timers, @player)) {
						clear_task(@timers[@player][2])
					}
					
					@timers[@player] = array(@id, time())
					@ptime = get_value('times.'.@id, @player)
					if(is_null(@ptime)) { 
						@ptime = 0
					} else {
						@ptime = ceil(@ptime)
					}
					
					set_plevel(@player, 0)
					set_pexp(@player, 0)
					play_sound(ploc(@player), array('sound': 'FIREWORK_BLAST'), @player)
					
					@level = array(0)
					
					@timers[@player][2] = set_interval(1000, closure(
						if(!ponline(@player) 
						|| !array_contains(sk_current_regions(@player), @id)) {
							if(ponline(@player) && ploc(@player)['y'] < 0) {
								pkill(@player)
							} else {
								@timers = import('timer')
								array_remove(@timers, @player)
								unbind(@player.'timerbreak')
								if(ponline(@player) && pworld(@player) == 'custom') {
									set_plevel(@player, 0)
									set_pexp(@player, 0)
								}
								clear_task()
							}
						} else {
							@level[0] += 1
							set_plevel(@player, @level[0])
							
							if(@level[0] <= @ptime) {
								@percent = round((@level[0] / @ptime) * 100)
								set_pexp(@player, @percent)
							}

							if(@level[0] + 5 > @ptime && @level[0] < @ptime) {
								play_sound(ploc(@player), array('sound': 'CLICK', 'pitch': 2), @player)
							} else if(@level[0] == @ptime) {
								play_sound(ploc(@player), array('sound': 'VILLAGER_NO'), @player)
							}
						}
					))
					
					if(!has_bind(@player.'timerbreak')) {
						bind('block_break', array('id': @player.'timerbreak'), array('player': @player), @e, @p = @player) {
							play_sound(ploc(@player), array('sound': 'VILLAGER_NO'), @p)
							@timers = import('timer')
							unbind()
							clear_task(@timers[@p][2])
							array_remove(@timers, @p)
						}
					}
					
					export('timer', @timers)
				
				} else if(@args[0] == 'stop') {
					
					if(array_index_exists(@timers, @player)
					&& @timers[@player][0] == @id) {
						@time = round((time() - @timers[@player][1]) / 1000, 1)
						unbind(@player.'timerbreak')
						clear_task(@timers[@player][2])
						array_remove(@timers, @player)
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
							@times = get_value('times', @id)
							if(!@times) {
								@times = array('top': array(array(@player, @time)))
								store_value('times', @id, @times)					
							} else {
								@place = 0
								for(@i = 0, @i < 10, @i++) {
									if(!@place) {
										if(!array_index_exists(@times['top'], @i) || @time < @times['top'][@i][1]) {
											array_insert(@times['top'], array(@player, @time), @i)
											@place = @i + 1
										}
									} else {
										if(array_index_exists(@times['top'], @i) && @times['top'][@i][0] == @player) {
											array_remove(@times['top'], @i)
										}
									}
								}
								if(@place) {
									switch(@place) {
										case 1:
											@place = '1st'
											_acc_add(@player, 250)
											tmsg(@player, color('gold').'+ 250 coins')
										case 2:
											@place = '2nd'
										case 3:
											@place = '3rd'
										default:
											@place = @place.'th'
									}
									tmsg(@player, 'You got a '.color('bold').@place.color('r').' place time for this course!')
									launch_firework(@loc, array(
										'strength': 1,
										'flicker': true,
										'trail': true,
										'colors': array(array(rand(256), rand(256), rand(256))),
										'fade': array(array(rand(256), rand(256), rand(256))),
										'type': 'BALL_LARGE',
									))
									if(array_size(@times['top']) > 10) {
										array_remove(@times['top'], 10)
									}
									store_value('times', @id, @times)
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
		}
	))
)