@month = simple_date('MMM');
@day = integer(simple_date('d'));
if(@month == 'Feb') {
    if(@day > 8 && @day < 16) {
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
