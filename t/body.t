use v6;
use Test;
use PDF::Style::Body;
use CSS::Properties;
use PDF::Class;
use PDF::Content::XObject;
use CSS::Units :mm, :pt, :px, :ops;

sub mm($_) { (0mm +css $_) }
sub pt($_) { (0pt +css $_) }

my PDF::Content::XObject $bg-image .= open("t/images/semitransparent.gif");
my CSS::Properties() $css = "size: a5; margin-left:3pt; background-image: url($bg-image); background-color: blue; opacity: .3; border: 0pt solid red";

my PDF::Style::Body $body .= new: :$css;
my @html = '<html>', $body.html-start;

constant LeftMargin = 3pt;
constant Borders = 0pt; # 1pt each side
constant DefaultBorders = 4pt; # 'medium' := 2px each side

is-approx mm($body.width), (148mm -css (LeftMargin +css Borders)), 'width - standard';
is-approx mm($body.height), (210mm -css Borders), 'height - standard';
is mm($body.width('margin')), 148mm, 'margin width';
is mm($body.height('margin')), 210mm, 'margin height';
my PDF::Class $pdf .= new;
my $page = $body.decorate($pdf.add-page);
is $page.width, pt(148mm), 'decorated page width';
is $page.height, pt(210mm), 'decorated page height';

$pdf.save-as: "t/body.pdf";
@html.append: $body.html-end, '</html>', '';
"t/body.html".IO.spurt: @html.join: "\n";

my PDF::Style::Body $body2 .= new: :style("size: 200pt 300pt");
is $body2.width, 200pt - DefaultBorders, 'width - width + height';
is $body2.height, 300pt - DefaultBorders, 'height - width + height';
is $body2.width('margin'), 200pt, 'margin width';
is $body2.height('margin'), 300pt, 'margin height';

$body2 = PDF::Style::Body.new: :style("size: 300px");
is $body2.width('margin'), pt(300px),'margin width';
is $body2.height('margin'), pt(300px), 'margin height';

my $gfx = $pdf.add-page.gfx;

$body2 = PDF::Style::Body.new: :$gfx, :style("size: a5 landscape");
is $body2.width('margin'), pt(210mm),'margin width';
is $body2.height('margin'), pt(148mm), 'margin height';

$body2 = PDF::Style::Body.new: :$gfx;
is $body2.width('margin'), $gfx.width,'margin width';
is $body2.height('margin'), $gfx.height, 'margin height';

done-testing;
