if(@id == 'all') {

    @times = get_values('times');
    x_new_thread('times', closure(){
        @players = array();
        foreach(@time in @times) {
            if(is_array(@time) && array_index_exists(@time, 'top')) {
                @lastTime = 1.0;
                @lastCount = 0;
                foreach(@i: @t in @time['top']) {
                    if(@t[1] == @lastTime){
                      @lastCount++;
                    } else {
                      @lastCount = 0;
                    }
                    if(!array_index_exists(@players, @t[0])) {
                        @players[@t[0]] = array(
                          'total': array_size(@time['top']) - @i + @lastCount,
                          'placement': @i + 1 - @lastCount,
                          'count': 1,
                        );
                    } else {
                        @players[@t[0]]['total'] += (array_size(@time['top']) - @i + @lastCount);
                        @players[@t[0]]['placement'] += (@i + 1 - @lastCount);
                        @players[@t[0]]['count']++;
                    }
                    @lastTime = @t[1];
                }
            }
        }
        @averages = array();
        foreach(@p: @score in @players) {
            @averages[] = array(@p, @score['total'], round(@score['placement'] / @score['count'], 1));
        }
        array_sort(@averages, closure(@left, @right){
            return(@left[1] < @right[1]);
        });
        x_run_on_main_thread_later(closure(){
            store_value('times', @averages[0..14]);
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
    @max = min(15, array_size(@array));
    for(@i = 0, @i < @max, @i++) {
        @array[@i][0] = get_value('uuids', @array[@i][0])['name'];
    }
    store_value('times', @id, associative_array('top': @array[cslice(0, @max - 1)]));
    msg('Finished recalculating times.');

}
