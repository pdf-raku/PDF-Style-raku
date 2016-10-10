use v6;
use Test;
use PDF::Style :pt;
use CSS::Declarations::Units;

is pt(10pt), 10;

is '%0.2f'.sprintf(pt(1in)), '72.00', 'pt(in)';
is '%0.2f'.sprintf(pt(10px)), '7.50', 'pt(px)';
is '%0.2f'.sprintf(pt(1pc)), '12.00', 'pt(pc)';
is '%0.2f'.sprintf(pt(1 does CSS::Declarations::Units::Keyed["em"])), '12.00', 'pt(em)';
is '%0.2f'.sprintf(pt(1 does CSS::Declarations::Units::Keyed["em"], :em(15))), '15.00', 'pt(em)';
is '%0.2f'.sprintf(pt(1 does CSS::Declarations::Units::Keyed["ex"])), '9.00', 'pt(ex)';

done-testing;
