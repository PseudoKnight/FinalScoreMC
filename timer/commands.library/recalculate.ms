@times = get_values('times', @id);
array_remove(@times, 'times.'.@id);
@array = array();
foreach(@key: @time in @times) {
    @array[] = array(split('.', @key)[2], @time);
}
array_sort(@array, closure(@left, @right){
    return(@left[1] > @right[1]);
});
@max = min(10, array_size(@array));
for(@i = 0, @i < @max, @i++) {
    @array[@i][0] = get_value('uuids', @array[@i][0])['name'];
}
store_value('times', @id, associative_array('top': @array[cslice(0, @max - 1)]));
msg('Finished recalculating times.');
