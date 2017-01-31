@worlds = import('worlds');
if(!@worlds) {
    @worlds = yml_decode(read('config.yml'));
    export('worlds', @worlds);
}
@loadedWorlds = get_worlds();
foreach(@id: @world in @worlds) {
    if(!is_array(@world) || array_contains(@loadedWorlds, @id)) {
        continue();
    }
    if(array_index_exists(@world, 'generator')) {
        create_world(@id, 'NORMAL', @world['environment'], @world['seed'], @world['generator']);
    } else {
        create_world(@id, 'NORMAL', @world['environment']);
    }
}
