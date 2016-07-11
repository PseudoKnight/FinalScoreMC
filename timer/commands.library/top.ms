@times = get_value('times', @id);
if(!@times || !array_index_exists(@times, 'top')) {
    die('No top times for '.to_upper(@id).'.');
}
msg(colorize('&e&m|------------------&e&l[ TOP TIMES - '.to_upper(@id).' ]&e&m---|'));
for(@i = 0, @i < array_size(@times['top']), @i++) {
    @time = '';
    if(@times['top'][@i][1] >= 60) {
        @time = simple_date('m\u0027m\u0027 ss.S', integer(@times['top'][@i][1] * 1000));
    } else {
        @time = simple_date('s.S', integer(@times['top'][@i][1] * 1000));
    }
    @time = substr(@time, 0, length(@time) - 2).'s';
    msg(colorize(' '.if(@i < 9, '&80').'&7'.(@i + 1).'&a [ '.@time.' ] &r'.@times['top'][@i][0]));
}
msg(colorize('&e&m|----------------------------------------------------|'));
