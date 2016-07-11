if(!has_value('times', @id)) {
    die('There are no stats to reset for '.to_upper(@id).'.')
}
@times = get_values('times', @id)
foreach(@key: @time in @times) {
    clear_value(@key)
}
msg('Reset stats for '.to_upper(@id).'.')
