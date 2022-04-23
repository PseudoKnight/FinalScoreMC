@loc = get_command_block();
@x = @loc['x'] + 4;
@y = @loc['y'] - 2;
@z = @loc['z'];
@world = @loc['world'];
@count = rand(5, 11);
while(@count-- > 0) {
	@loc = array(@x, @y, @z, @world);
	queue_push(closure(){
		set_block(@loc, 'SLIME_BLOCK');
		play_sound(@loc, array(sound: 'BLOCK_SLIME_BLOCK_STEP'));
	}, 'slime');
	@x += rand(2);
	@z += rand(3) - 1;
}