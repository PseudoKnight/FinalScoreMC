proc('_create_dungeon', @region, @world) {
	@scale = 2
	@minroomsize = 3
	@maxroomsize = 9
	@height = 3
	
	@floor = '98:1'
	@mat = array('1:0', '98:0', '0:0')

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
	@dungeon = associative_array()
	for(@i = 0, @i < @width, @i++) {
		@dungeon[@i] = array()
		array_resize(@dungeon[@i], @length, 0)
	}
	
	#define rooms
	@rooms = array()
	@nrooms = 0
	
	# place rooms
	for(@r = 1, @r < @length, @r = @r + 2) {
		for(@c = 1, @c < @width, @c = @c + 2) {
			if(!@dungeon[@c][@r] && rand(2)) {
				@roomwidth = rand(((@maxroomsize - @minroomsize) / 2) + 1) * 2 + @minroomsize
				@roomlength = rand(((@maxroomsize - @minroomsize) / 2) + 1) * 2 + @minroomsize
				
				# check if room collides
				for(@r2 = @r, @r2 < (@roomlength + @r), @r2 = @r2 + 2) {
					for(@c2 = @c + 2, @c2 < (@roomwidth + @c), @c2 = @c2 + 2) {
						if(!array_index_exists(@dungeon, @c2)
						|| !array_index_exists(@dungeon[@c2], @r2)
						|| @dungeon[@c2][@r2]) {
							break(3)
						}
					}
				}
				# save room
				@rooms[@nrooms] = array(
					'r1': @r,
					'c1': @c,
					'r2': @r + @roomlength,
					'c2': @c + @roomwidth,
				)
				@nrooms++
				
				# mask room
				for(@r2 = @r, @r2 < (@roomlength + @r), @r2++) {
					for(@c2 = @c, @c2 < (@roomwidth + @c), @c2++) {
						@dungeon[@c2][@r2] = 2
					}
				}
				
				@c = @c + @roomwidth - 1
			}
		}
	}
	
	# open rooms
	
	# create halls
	
	# place stairs
	
	# cleanup
	
	# build
	for(@z = 0, @z < @regionlength, @z++) {
		for(@x = 0, @x < @regionwidth, @x++) {
			#floor
			set_block_at(array(@coords[1][0] + @x, @coords[1][1], @coords[1][2] + @z, @world), @floor)
			#walls
			@r = floor(@z / @scale)
			@c = floor(@x / @scale)
			for(@y = 1, @y <= @height, @y++) {
				set_block_at(array(@coords[1][0] + @x, @coords[1][1] + @y, @coords[1][2] + @z, @world), @mat[@dungeon[@c][@r]])
			}
			#ceiling
		}
	}
}
