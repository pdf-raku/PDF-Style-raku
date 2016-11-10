use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $style = "font-family: Helvetica; width: 300pt; position:absolute; left: 20pt; top: 30pt; border: 1pt solid red";
my $css = CSS::Declarations.new( :$style );
my $Vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
my $Page = $Vp.add-page($pdf);
$Page.gfx.comment-ops = True;
my @Html = '<html>', '<body>', $Vp.html-start;

sub show-text($text, :$css!, |c) {
    my $box = $Vp.box( :$text, :$css, |c );
    $box.render($Page);
    @Html.push: $box.html;
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
    $css.top += 15pt;

    $css.font-weight = 'normal';
    show-text($body ~ ' ' ~ $css.write, :$css);
    $css.top += 120pt;
}

$css.delete("text-align");
$css.top = 30pt;
$css.left = 350pt;
$css.width = 220pt;

for <top center bottom> -> $valign {
    my $header = [~] '*** VALIGN:', $valign, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        --ENOUGH!!--

    note "% **** valign $valign *** ";
    $css.delete("height");
    $css.font-weight = 'bold';
    show-text($header, :$css);

    $css.top += 15pt;
    $css.font-weight = 'normal';
    $css.height = 130pt;
    my $text = $body ~ $style;
    show-text($text, :$css, :$valign);

    $css.top += 165pt;
}

note "% **** position right *** ";

$css.delete('left');
$css.right = 25pt;
$css.height = 100pt;
$css.top += 12pt;

show-text( $css.write, :$css );

note "% **** position bottom *** ";

$css.left = 20pt;
$css.height = 100pt;
$css.bottom = 160pt;
$css.delete('top');

show-text( $css.write, :$css );

lives-ok {$pdf.save-as: "t/00basic.pdf"};

@Html.append: $Vp.html-end, '</body>', '</html>', '';
"t/00basic.html".IO.spurt: @Html.join: "\n";

done-testing;
