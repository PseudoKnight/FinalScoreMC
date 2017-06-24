if(!has_permission('command.recalculatetimes')) {
    die('You do not have permission to recalculate times.');
}
if(@id == 'all') {

    @times = get_values('times');
    x_new_thread('times', closure(){
        @players = array();
        foreach(@key: @time in @times) {
            if(is_array(@time) && @key != 'times') {
                @lastTime = 1.0;
                @lastCount = 0;
                foreach(@i: @t in @time) {
                    if(@t[2] == @lastTime){
                      @lastCount++;
                    } else {
                      @lastCount = 0;
                    }
                    if(!array_index_exists(@players, @t[0])) {
                        @players[@t[0]] = array(@t[1], array_size(@time) - @i + @lastCount);
                    } else {
                        @players[@t[0]][1] += array_size(@time) - @i + @lastCount;
                    }
                    @lastTime = @t[2];
                }
            }
        }
        @averages = array();
        foreach(@uuid: @score in @players) {
            @averages[] = array(@uuid, @score[0], @score[1]);
        }
        array_sort(@averages, closure(@left, @right){
            return(@left[2] < @right[2]);
        });
        x_run_on_main_thread_later(closure(){
            store_value('times', @averages[0..19]);
        });
    });

} else {

    @times = get_values('times', @id);
    array_remove(@times, 'times.'.@id);
    @array = array();
    foreach(@key: @time in @times) {
        @array[] = array(split('.', @key)[2], @time);
    }
    array_sort(@array, closure(@left, @right){
        return(@left[1] > @right[1]);
    });
    @max = min(20, array_size(@array));
    for(@i = 0, @i < @max, @i++) {
        array_insert(@array[@i], get_value('uuids', @array[@i][0])['name'], 1);
    }
    store_value('times', @id, @array[cslice(0, @max - 1)]);
    msg('Finished recalculating times.');

}
