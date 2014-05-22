proc('_create_dungeon', @region, @world, @scale) {
	@minroomsize = 3
	@maxroomsize = 11
	@height = 4
	
	@mat = array(
		' ': '7:0', 
		'wall': '98:0', 
		'room': '0:0',
		'door': '98:3',
		'column': '47:0',
	)
	
	@ceiling = '98:0'
	@floor = '98:1'

	# get size, scaled
	if(!sk_region_exists(@world, @region), die('Region doesn\'t exist.'))
	
	@coords = sk_region_info(@region, @world, 0)
	@regionwidth = @coords[0][0] - @coords[1][0]
	@regionlength = @coords[0][2] - @coords[1][2]
	@width = ceil(@regionwidth / @scale)
	@length = ceil(@regionlength / @scale)
	
	if(!(@width % 2), @width--)
	if(!(@length % 2), @length--)
	if(@width < 21 || @length < 21, die('Region too small'))
	
	# define grid
	@dungeon = array()
	for(@c = 0, @c < @width, @c++) {
		@dungeon[@c] = array()
		for(@r = 0, @r < @length, @r++) {
			if(@r == 0 || @r == @length - 1
			|| @c == 0 || @c == @width - 1) {
				@type = 'wall'
			} else {
				@type = ' '
			}
			@dungeon[@c][@r] = @type
		} 
	}
	
	#define rooms
	@rooms = array()
	@nroom = 0
	
	# place rooms
	queue_push(closure(){
	for(@r = 1, @r < @length, @r += 2) {
		for(@c = 1, @c < @width, @c += 2) {
			if(@dungeon[@c][@r] == ' ') {
				@roomwidth = rand(((@maxroomsize - @minroomsize) / 2) + 1) * 2 + @minroomsize
				@roomlength = rand(((@maxroomsize - @minroomsize) / 2) + 1) * 2 + @minroomsize
				while(@roomwidth > 1 && _c_collides(@dungeon, @c, @r, @roomwidth)) {
					@roomwidth -= 2
				}
				while(@roomlength > -1 && _r_collides(@dungeon, @c, @r, @roomlength)) {
					@roomlength -= 2
				}
				if(@roomwidth == -1 || @roomlength == -1) { 
					continue() 
				}
				
				# save room
				@rooms[@nroom] = array(
					'r1': @r,
					'c1': @c,
					'r2': @r + @roomlength,
					'c2': @c + @roomwidth,
				)
				
				# mask room
				for(@r2 = @r - 1, @r2 <= @roomlength + @r, @r2++) {
					for(@c2 = @c - 1, @c2 <= @roomwidth + @c, @c2++) {
						if(@r2 >= @r && @r2 < @roomlength + @r
						&& @c2 >= @c && @c2 < @roomwidth + @c) {
							switch(rand(100)) {
							case 0..3:
								@dungeon[@c2][@r2] = 'column'
							default:
								@dungeon[@c2][@r2] = 'room'
							}
						} else if(@dungeon[@c2][@r2] != 'door') {
							@dungeon[@c2][@r2] = 'wall'
						}
					}
				}
				
				@doors = 2
				while(@doors > 0) {
					if(rand(2)) {
						if(rand(2)) {
							@r2 = @r - 1
						} else {
							@r2 = @r + @roomlength
						}
						@c2 = @c + rand(0, (@roomwidth + 1) / 2) * 2
					} else {
						if(rand(2)) {
							@c2 = @c - 1
						} else {
							@c2 = @c + @roomwidth
						}
						@r2 = @r + rand(0, (@roomlength + 1) / 2) * 2
					}
					
					if(@r2 == 0 || @r2 == @length - 1
					|| @c2 == 0 || @c2 == @width - 1) {
						continue()
					}
					
					@dungeon[@c2][@r2] = 'door'
					@doors -= 1
				}
				
				@nroom += 1
				@c = @c + @roomwidth - 1
			}
		}
	}
	}, 'd1')
	
	# place stairs
	
	# build
	for(@z = 0, @z < @length * @scale, @z++) {
		queue_push(closure(){
		for(@x = 0, @x < @width * @scale, @x++) {
			@r = floor(@z / @scale)
			@c = floor(@x / @scale)
			#floor
			if(@dungeon[@c][@r] == 'column' && !rand(4)) {
				set_block_at(array(@coords[1][0] + @x, @coords[1][1], @coords[1][2] + @z, @world), '52:0')
				set_spawner_type(array(@coords[1][0] + @x, @coords[1][1], @coords[1][2] + @z, @world), 'ZOMBIE')
			} else {
				set_block_at(array(@coords[1][0] + @x, @coords[1][1], @coords[1][2] + @z, @world), @floor)
			}
			#walls
			for(@y = 1, @y <= @height, @y++) {
				if(@y != @height && @dungeon[@c][@r] != 'wall') {
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat[@dungeon[@c][@r]])
				} else if(@dungeon[@c][@r] == 'door' || @dungeon[@c][@r] == 'wall') {
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['wall'])
				} else {
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['room'])
				}
			}
			#ceiling
		}
		}, 'd1')
	}
}

proc('_r_collides', @dungeon, @c, @r, @roomlength) {
	for(@r2 = @r, @r2 < @roomlength + @r, @r2 += 2) {
		if(!array_index_exists(@dungeon[@c], @r2)
		|| @dungeon[@c][@r2] != ' ') { 
			return(true)
		}
	}
}

proc('_c_collides', @dungeon, @c, @r, @roomwidth) {
	for(@c2 = @c + 2, @c2 < @roomwidth + @c, @c2 += 2) {
		if(!array_index_exists(@dungeon, @c2)
		|| @dungeon[@c2][@r] != ' ') { 
			return(true)
		}
	}
}
