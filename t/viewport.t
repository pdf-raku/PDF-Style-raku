use v6;
use Test;
use PDF::Style::Viewport;
use CSS::Properties;
use PDF::Lite;

my $bg-image = PDF::Content::Image.open("t/images/semitransparent.gif");
my CSS::Properties $css .= new: :style("size: a5; margin-left:3pt; background-image: url($bg-image); background-color: blue; opacity: .3; border: 1pt solid red");

my PDF::Style::Viewport $vp .= new: :$css;
constant LeftMargin = 3;
constant Borders = 2; # 1px each side
constant DefaultBorders = 4; # 'medium' := 2px each side

is $vp.width, 420 - LeftMargin - Borders, 'width - standard';
is $vp.height, 595 - Borders, 'height - standard';
is $vp.width('margin'), 420, 'margin width';
is $vp.height('margin'), 595, 'margin height';
my PDF::Lite $pdf .= new;
my $page = $vp.decorate($pdf.add-page);
is $page.width, 420, 'decorated page width';
is $page.height, 595, 'decorated page height';

$pdf.save-as: "t/viewport.pdf";

my PDF::Style::Viewport $vp2 .= new: :style("size: 200pt 300pt");
is $vp2.width, 200 - DefaultBorders, 'width - width + height';
is $vp2.height, 300 - DefaultBorders, 'height - width + height';
is $vp2.width('margin'), 200, 'margin width';
is $vp2.height('margin'), 300, 'margin height';

$vp2 = PDF::Style::Viewport.new: :style("size: 300px");
is $vp2.width('margin'), 300,'margin width';
is $vp2.height('margin'), 300, 'margin height';

my $gfx = $pdf.add-page.gfx;

$vp2 = PDF::Style::Viewport.new: :$gfx, :style("size: a5 landscape");
is $vp2.width('margin'), 595,'margin width';
is $vp2.height('margin'), 420, 'margin height';

$vp2 = PDF::Style::Viewport.new: :$gfx;
is $vp2.width('margin'), $gfx.width,'margin width';
is $vp2.height('margin'),$gfx.height, 'margin height';

done-testing;
