@month = simple_date('MMM');
@day = integer(simple_date('d'));
if(@month == 'Feb') {
    if(@day > 9 && @day < 15) {
        include('seasons.library/valentines.ms');
    }
} else if(@month == 'Apr') {
    if(@day > 7) {
        include('seasons.library/easter.ms');
    }
} else if(@month == 'Oct') {
    if(@day > 7) {
        include('seasons.library/halloween.ms');
    }
}
