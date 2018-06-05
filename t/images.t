use v6;
use Test;
plan 1;

use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Properties::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my PDF::Style::Viewport $vp .= new;
my CSS::Properties $css .= new: :style("font-family:Helvetica; height:250pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', '<body>', $vp.html-start;

my PDF::Lite $pdf .= new;
my $page = $vp.decorate: $pdf.add-page;
$page.gfx.comment-ops = True;
my $n;

my $image = "t/images/snoopy-happy-dance.jpg";

for [
      { },
      { :background-color<rgba(255,0,0,.2)>, :width(210pt) },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, :width<160pt> },
      { :min-width<240pt>, :opacity<.3>, :border("1px solid black") },
      ] {

    test($vp, $css, $_, :$image,);
}

my $xobject = $page.gfx.load-image($image);

test($vp, $css, {}, :$xobject, :caption('testing of xobject element'));

lives-ok {$pdf.save-as: "t/images.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/images.html".IO.spurt: @Html.join: "\n";

sub test($vp, $base-css, $settings = {}, Str :$caption is copy, |c) {
    my $css = $base-css.clone;
    $css.set-properties(|$settings);
    my $elem = $vp.element( :$css, |c );
    @Html.push: $elem.html;
    $page.gfx.do(.xobject, .left, .bottom) with $elem;

    $caption //= ~ CSS::Properties.new: |$settings;
    if $caption {
        my $caption-css = $base-css.clone(
            :border("1pt solid black"),
            :background-color("rgba(200,200,200,.5)"),
           );
        $caption-css.left ➕= 8pt;
        $caption-css.width = ($elem.width - 12)pt;
        $caption-css.top = $css.top ➕ 8pt;
        $caption-css.delete('height');
        my $caption-box = $vp.element( :css($caption-css), :text($caption) );
        @Html.push: $caption-box.html;
        $page.gfx.do(.xobject, .left, .bottom) with $caption-box;
    }

    if ++$n %% 2 {
        $base-css.top ➕= 280pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left ➕= 260pt;
    }
}

done-testing;
