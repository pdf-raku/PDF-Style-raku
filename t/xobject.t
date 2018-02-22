use v6;
use Test;
plan 1;

use PDF::Style::Viewport;
use PDF::Lite;
use CSS::Declarations;
use CSS::Declarations::Units :ops, :pt;

my PDF::Style::Viewport $vp .= new;

my PDF::Lite $pdf .= new;
my $page = $vp.decorate: $pdf.add-page;
$page.gfx.comment-ops = True;

my CSS::Declarations $css .= new: :style("font-family:Vera; font-weight: 200;width:250pt; height:80pt; border: 1px solid green; padding:2pt");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
        --ENOUGH!!--

$css.left = '50pt';
$css.bottom = '700pt';

$page.graphics: -> $gfx {

    my $text-elem = $vp.element( :$text, :$css);
    does-ok $text-elem.xobject, PDF::Content::XObject;
    $gfx.do(.xobject, .left, .bottom) with $text-elem;;

    my Str $image = "t/images/snoopy-happy-dance.jpg";
    $css.opacity = .5;
    $css.delete("height");
    my $image-elem = $vp.element(:$image, :$css);
    $gfx.do(.xobject, .left, .bottom - $image-elem.height('padding'))
        with $image-elem;
}

$pdf.save-as: "t/xobject.pdf";
