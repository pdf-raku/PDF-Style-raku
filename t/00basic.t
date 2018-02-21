use v6;
use Test;
plan 7;

use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my $style = "font-family: Helvetica; width: 300pt; position:absolute; left: 20pt; top: 30pt; border: 1pt solid red";
my CSS::Declarations $css .= new( :$style );
my PDF::Style::Viewport $vp .= new;

my PDF::Lite $pdf .= new;
my $Page = $vp.add-page($pdf);
$Page.gfx.comment-ops = True;
my @Html = '<html>', '<body>', $vp.html-start;

sub show-text($text, :$css!) {
    my $elem = $vp.element( :$text, :$css);
    $elem.render($Page);
    @Html.push: $elem.html;
    $elem;
}

for <left center right justify> -> $alignment {
    my $header = [~] '*** ALIGN:', $alignment, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
        --ENOUGH!!--

    note "% **** align $alignment *** ";
    $css.text-align = $alignment;
    $css.font-weight = 'bold';

    show-text($header, :$css);
    $css.top  ➕= 15pt;

    $css.font-weight = 'normal';
    show-text($body ~ ' ' ~ $css.write, :$css);
    $css.top  ➕= 120pt;
}

$css.delete("text-align");
$css.top = 30pt;
$css.left = 350pt;
$css.width = 220pt;

for <top middle bottom> -> $valign {
    my $header = [~] '*** VERTICAL-ALIGN:', $valign, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        --ENOUGH!!--

    note "% **** valign $valign *** ";
    $css.delete('height', 'vertical-align');
    $css.font-weight = 'bold';
    show-text($header, :$css);

    $css.top  ➕= 15pt;
    $css.font-weight = 'normal';
    $css.height = 130pt;
    $css.vertical-align = $valign;
    my $text = $body ~ $style;
    show-text($text, :$css);

    $css.top  ➕= 165pt;
}

note "% **** position right *** ";

$css.delete('left', 'vertical-align');
$css.right = 25pt;
$css.height = 100pt;
$css.top  ➕= 12pt;

my $elem = show-text( $css.write, :$css );
is $elem.height, 100, 'content height';
is $elem.height('border'), 102, 'border height';
is $elem.width, 220, 'content width';
is $elem.width('border'), 222, 'border width';
is $elem.left, 345, 'content left';
is $elem.left('border'), 344, 'border left';

note "% **** position bottom *** ";

$css.left = 20pt;
$css.height = 100pt;
$css.bottom = 160pt;
$css.delete('top');

show-text( $css.write, :$css );

lives-ok {$pdf.save-as: "t/00basic.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/00basic.html".IO.spurt: @Html.join: "\n";

done-testing;
