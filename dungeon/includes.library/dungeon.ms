proc('_create_dungeon', @region, @world, @scale) {
	@minroomsize = 3
	@maxroomsize = 11
	@height = 4
	
	@mat = array(
		' ': '7:0', 
		'wall': '98:0', 
		'room': '0:0',
		'door': '0:0',
		'column': '47:0',
		'stairs': '109:0',
		'chest': '54:0',
		'stairs': '109:2',
		'ceiling': '98:0',
		'floor': '98:1',
	)

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
	
	# place entrance stairway
	@c = (rand(2, (@width - 1) / 2) * 2) + 1
	@r = (rand(0, (@length - 5) / 2) * 2) + 1
	for(@r2 = @r - 1, @r2 <= 5 + @r, @r2++) {
		for(@c2 = @c - 1, @c2 <= 1 + @c, @c2++) {
			if(@c2 == @c && @r2 >= @r - 1 && @r2 < @r + 5) {
				if(@r2 == @r - 1) {
					@dungeon[@c2][@r2] = 'door'
				} else {
					@dungeon[@c2][@r2] = 'stairs'
				}
			} else {
				@dungeon[@c2][@r2] = 'wall'
			}
		}
	}
	
	@rooms[] = array(
		'r1': @r,
		'c1': @c,
		'r2': @r + 5,
		'c2': @c,
	)

	@nroom = 1
	
	# place rooms
	queue_push(closure(){
	for(@r = 1, @r < @length, @r += 2) {
		for(@c = 1, @c < @width, @c += 2) {
			if(@dungeon[@c][@r] == ' ') {
				@roomwidth = rand(((@maxroomsize - @minroomsize) / 2) + 1) * 2 + @minroomsize
				@roomlength = rand(((@maxroomsize - @minroomsize) / 2) + 1) * 2 + @minroomsize
				
				# check placement
				for(@r2 = @r, @r2 < @roomlength + @r, @r2 += 2) {
					@c2 = @c
					if(@r2 >= @length || @dungeon[@c2][@r2] != ' ') {
						@roomlength = @r2 - @r - 1
						break()
					}
					for(@c2 = @c, @c2 < @roomwidth + @c, @c2 += 2) {
						if(@c2 >= @width || @dungeon[@c2][@r2] != ' ') {
							@roomwidth = @c2 - @c - 1
							break()
						}
					}
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
							case 4:
								@dungeon[@c2][@r2] = 'chest'
							default:
								@dungeon[@c2][@r2] = 'room'
							}
						} else if(@dungeon[@c2][@r2] != 'door') {
							@dungeon[@c2][@r2] = 'wall'
						}
					}
				}
				
				while(true) {
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
					break()
				}
				
				@nroom += 1
				@c = @c + @roomwidth - 1
			} else if(@dungeon[@c][@r] == 'stairs') {
			
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
				set_block_at(array(@coords[1][0] + @x, @coords[1][1], @coords[1][2] + @z, @world), @mat['floor'])
			}
			#walls
			for(@y = 1, @y <= @height, @y++) {
				switch(@dungeon[@c][@r]) {
				case 'wall':
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['wall'])
				case 'room':
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['room'])
				case 'door': 
					if(@y != @height) { 
						set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['room'])
					} else {
						set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['wall'])
					}
				case 'chest':
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['chest'])
					@dungeon[@c][@r] = 'room'
				case 'column':
					if(@y != @height) { 
						set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['column'])
					} else {
						set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['room'])
					}
				case 'stairs':
					if(@z - (@rooms[0]['r1'] * @scale) - 1 == @y) {
						set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['stairs'])
					} else {
						set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat['room'])
					}
				default:
					set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat[' '])
				}
			}
			#ceiling
			# if(@dungeon[@c][@r] == 'stairs') {
				# if(@z - (@rooms[0]['r1'] * @scale) - 1 == @height + 1) {
					# set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @height + 1, @coords[1][2] + @z, @world), @mat['stairs'])
				# } else if(@z - (@rooms[0]['r1'] * @scale) - 1 < @height + 1) {
					# set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @height + 1, @coords[1][2] + @z, @world), @mat['room'])
				# }
			# } else {
				# set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @height + 1, @coords[1][2] + @z, @world), @mat['ceiling'])
			# }
		}
		}, 'd1')
	}
}
