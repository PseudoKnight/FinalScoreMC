@times = get_values('times', @id);
@total = 0;
@alltimes = array();
foreach(@time in @times) {
    if(is_array(@time)) {
        continue();
    }
    @total += @time;
    @alltimes[] = @time;
}
array_sort(@alltimes, 'NUMERIC');
@median = array_size(@alltimes) / 2;
if(array_size(@alltimes) % 2 > 0) {
    @median = (@alltimes[floor(@median)] + @alltimes[ceil(@median)]) / 2;
} else {
    @median = @alltimes[@median];
}
@avg = round(@total / (array_size(@times) - 1), 1);
msg('Median time: '.color('green').@median.color('r').' | Average time: '.color('green').@avg);
