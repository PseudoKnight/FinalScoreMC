@time = get_value('times.'.@id, puuid(player(), true));
if(!@time) {
    die('You do not have a time for '.to_upper(@id).'.');
}
msg('Your best time for '.color('gold').to_upper(@id).color('r').' is '.color('green').@time.' seconds.');
