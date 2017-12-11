use v6;
use Test;
plan 1;

use PDF::Style::Viewport;
use PDF::Lite;
use CSS::Declarations;
##use PDF::Content::XObject;

my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Lite.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;

my $css = CSS::Declarations.new: :style("font-family:Vera; font-weight: 200;width:250pt; height:80pt; border: 1px solid green; padding:2pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
        --ENOUGH!!--

my $text-elem = $vp.element( :$text, :$css);
my $text-xo = $text-elem.xobject;
does-ok $text-xo, PDF::Content::XObject;
my Str $image = "t/images/snoopy-happy-dance.jpg";
$css.opacity = .5;
$css.delete("height");
my $image-xo = $vp.element(:$image, :$css).xobject;

$page.graphics: {
    .do($text-xo, 50, 700);
    .do($image-xo, 50, 400);
}

$pdf.save-as: "t/xobject.pdf";
