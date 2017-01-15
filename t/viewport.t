use v6;
use Test;
use PDF::Style::Viewport;
use CSS::Declarations;

my $bg-image = PDF::Content::Image.open("t/images/semitransparent.gif");
my $css = CSS::Declarations.new: :style("size: a5; margin-left: .5cm; background-image: url($bg-image); background-color: blue; opacity: .3;");
warn $css;

todo "write general view point styling tests", 3;
my $vp = PDF::Style::Viewport.new: :$css;
is $vp.width, 420;
is $vp.height, 595;
flunk 'general styling tests';

done-testing;
