@loc = get_command_block();
@x1 = @loc['x'] + 4;
@y1 = @loc['y'] - 2;
@z1 = @loc['z'];
@x2 = @x1;
@y2 = @y1;
@z2 = @z1;
@world = @loc['world'];
@count = rand(6, 11);
while(@count-- > 0) {
	@loc1 = array(@x1, @y1, @z1, @world);
	@loc2 = array(@x2, @y2, @z2, @world);
	queue_push(closure(){
		set_block(@loc1, 'SLIME_BLOCK');
		play_sound(@loc1, array(sound: 'BLOCK_SLIME_BLOCK_STEP', pitch: 0.5 + rand() * 1.5));
	}, 'slime');
	queue_push(closure(){
		set_block(@loc2, 'SLIME_BLOCK');
		play_sound(@loc2, array(sound: 'BLOCK_SLIME_BLOCK_STEP', pitch: 0.5 + rand() * 1.5));
	}, 'slime');
	@x1 += rand(2);
	@z1 += rand(3) - 1;
	@x2 += rand(2);
	@z2 += rand(3) - 1;
}