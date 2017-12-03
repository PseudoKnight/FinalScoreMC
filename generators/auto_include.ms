proc _generator_create(@type, @config, @region, @world, @seed) {
	include('generator.library/'.@type.'.ms');
	_generate(@config, @region, @world, @seed);
}
