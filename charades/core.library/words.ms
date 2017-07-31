proc _get_categories() {
	return(array('easy', 'medium', 'hard', 'very-hard', 'idioms', 'animals', 'people', 'movies', 'tv-shows', 'books'));
}

proc _get_word(@closure) {
	@inputMap = array(
		'easy': 'charades_easy',
		'medium': 'charades_moderate',
		'hard': 'charades_hard',
		'very-hard': 'charades_very_hard',
		'idioms': 'idioms_popular',
		'animals': 'animal_names',
		'people': 'people_character_names_popular',
		'movies': 'movie_names_popular',
		'tv-shows': 'tv_show_names_popular',
		'books': 'book_names_popular',
	);
	
	@charades = import('charades');
	@category = @inputMap[@charades['category']];
	@words = get_value('charades', @category);
	if(!@words) {
		http_request('http://www.wordgenerator.net/application/p.php?type=1&id='.@category, array(
			'method': 'GET',
			'success': closure(@response){
				if(!@response['error']) {
					@words = split(',', @response['body']);
					@word = @words[0];
					if(@charades['category'] == 'books') {
						@word = split(' by ', @word)[0];
					}
					array_remove(@words, 0);
					store_value('charades', @category, @words);
					execute(@word, @closure);
				}
			}
		));
	} else {
		@word = @words[0];
		if(@charades['category'] == 'books') {
			@word = split(' by ', @word)[0];
		}
		array_remove(@words, 0);
		store_value('charades', @category, @words);
		execute(@word, @closure);
	}
}
