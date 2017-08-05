proc _get_categories() {
	return(array('easy', 'medium', 'hard', 'very-hard', 'idioms', 'animals', 'people', 'movies', 'tv-shows', 'books'));
}

proc _get_match(@one, @two) {
	@one = reg_replace('^(a|the)\\s', '', to_lower(@one));
	@two = reg_replace('^(a|the)\\s', '', to_lower(@two));
	return(levenshtein(@one, @two));
}

proc _get_word_from_list(@words, @category) {
	@word = '';
	do {
		@word = @words[0];
		if(@category == 'book_names_popular') {
			@word = trimr(split('by', @word)[0]);
		}
		array_remove(@words, 0);
		store_value('charades', @category, @words);
	} while(length(@word) < 3 && @words);
	return(@word);
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
					execute(_get_word_from_list(@words, @category), @closure);
				}
			}
		));
	} else {
		execute(_get_word_from_list(@words, @category), @closure);
	}
}