use v6;
use Test;
plan 1;

use PDF::Style::Body;
use PDF::Class;
use CSS::Properties;
use CSS::Units :ops, :pt;

my PDF::Style::Body $body .= new;

my PDF::Class $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment = True;

my CSS::Properties() $css = "font-family:Vera; font-weight:200; width:250pt; height:80pt; border: 1px solid green; padding:2pt";

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
        --ENOUGH!!--

$css.left = '50pt';
$css.bottom = '700pt';

$page.graphics: -> $gfx {
    my $text-elem = $body.element( :$text, :$css);
    $text-elem.render($gfx);

    my Str $image = "t/images/snoopy-happy-dance.jpg";
    $css.delete("height");
    $css.opacity = .5;
    my $image-elem = $body.element(:$image, :$css);
    $image-elem.translate: 0, -$image-elem.height('padding');
    .render($gfx, .left, .bottom)
        with $image-elem;
    $image-elem.css.opacity = 1;
     $image-elem.translate: 30, -30;
    .render($gfx, .left, .bottom)
        with $image-elem;
}

lives-ok {$pdf.save-as: "t/render.pdf"};
