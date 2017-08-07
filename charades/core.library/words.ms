proc _get_categories() {
	return(array('easy', 'medium', 'hard', 'very-hard', 'idioms', 'animals', 'people', 'movies', 'tv-shows', 'books'));
}

proc _get_match(@one, @two) {
	// ignore beginning articles
	@one = reg_replace('^(a|the)\\s', '', to_lower(@one));
	@two = reg_replace('^(a|the)\\s', '', to_lower(@two));
	
	// ignore single spelling errors
	if(levenshtein(@one, @two) < 2) {
		return(2);
	}
	
	// it's not a match, but let's check if they got one word right
	@words = parse_args(@one);
	foreach(@word in @words) {
		if(length(@word) > 3 && string_position(@two, @word) >= 0) {
			return(1);
		}
	}
	
	return(0);
}

proc _get_word_from_list(@words, @category) {
	@word = @words[0];
	if(@category == 'book_names_popular') {
		@word = trimr(split('by', @word)[0]);
	}
	array_remove(@words, 0);
	store_value('charades', @category, @words);
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
					@words = split(',', replace(@response['body'], '\n', ''));
					execute(_get_word_from_list(@words, @category), @closure);
				}
			}
		));
	} else {
		execute(_get_word_from_list(@words, @category), @closure);
	}
}
