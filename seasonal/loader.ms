@month = simple_date('MMM');
if(@month == 'Oct') {
    include('seasons.library/halloween.ms');
} else if(@month == 'Apr') {
    include('seasons.library/easter.ms');
}
