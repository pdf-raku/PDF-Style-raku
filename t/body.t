use v6;
use Test;
use PDF::Style::Body;
use CSS::Properties;
use PDF::Lite;
use PDF::Content::XObject;
use CSS::Properties::Units :mm, :pt;

my $bg-image = PDF::Content::XObject.open("t/images/semitransparent.gif");
my CSS::Properties $css .= new: :style("size: a5; margin-left:3pt; background-image: url($bg-image); background-color: blue; opacity: .3; border: 1pt solid red");

my PDF::Style::Body $body .= new: :$css;
my @html = '<html>', $body.html-start;

constant LeftMargin = 3mm;
constant Borders = 2mm; # 1px each side
constant DefaultBorders = 4mm; # 'medium' := 2px each side

is $body.width, 148 - LeftMargin - Borders, 'width - standard';
is $body.height, 210 - Borders, 'height - standard';
is $body.width('margin'), 148, 'margin width';
is $body.height('margin'), 210, 'margin height';
my PDF::Lite $pdf .= new;
my $page = $body.decorate($pdf.add-page);
is $page.width, 148, 'decorated page width';
is $page.height, 210, 'decorated page height';

$pdf.save-as: "t/body.pdf";
@html.append: $body.html-end, '</html>', '';
"t/body.html".IO.spurt: @html.join: "\n";

my PDF::Style::Body $body2 .= new: :style("size: 200pt 300pt");
is $body2.width, 200 - DefaultBorders, 'width - width + height';
is $body2.height, 300 - DefaultBorders, 'height - width + height';
is $body2.width('margin'), 200, 'margin width';
is $body2.height('margin'), 300, 'margin height';

$body2 = PDF::Style::Body.new: :style("size: 300px");
is $body2.width('margin'), 300,'margin width';
is $body2.height('margin'), 300, 'margin height';

my $gfx = $pdf.add-page.gfx;

$body2 = PDF::Style::Body.new: :$gfx, :style("size: a5 landscape");
is $body2.width('margin'), 210,'margin width';
is $body2.height('margin'), 148, 'margin height';

$body2 = PDF::Style::Body.new: :$gfx;
is (0pt +$body2.width('margin')), (0pt + $gfx.width),'margin width';
is (0pt + $body2.height('margin')), (0pt + $gfx.height), 'margin height';

done-testing;
