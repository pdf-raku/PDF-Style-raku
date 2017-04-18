use v6;
use Test;
plan 1;

use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new;
my $css = CSS::Declarations.new: :style("font-family:Helvetica; height:250pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)");
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Lite.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

my $image = "t/images/snoopy-happy-dance.jpg";

for [
      { },
      { :background-color<rgba(255,0,0,.2)>, :width<200pt> },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, :width<160pt> },
      { :min-width<240pt>, :opacity<.3>, :border("1px solid black") },
      ] {

    test($vp, $css, $_, :$image);
}

lives-ok {$pdf.save-as: "t/images.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/images.html".IO.spurt: @Html.join: "\n";

sub test($vp, $css, $settings = {}, |c) {
    my $base-css = $css.clone;
    $css.set-properties(|$settings);
    my $elem = $vp.element( :$css, |c );
    @Html.push: $elem.html;
    $elem.render($page);

    my $caption-css = $css.clone(
        :border("1pt solid black"),
        :background-color("rgba(200,200,200,.5)"),
    );
    $caption-css.left ➕= 8pt;
    $caption-css.width = ($elem.width - 12)pt;
    $caption-css.top = $css.top ➕ 8pt;
    $caption-css.delete('height');
    my $text = ~ CSS::Declarations.new: |$settings;
    if $text {
        my $caption-box = $vp.element( :css($caption-css), :$text );
        @Html.push: $caption-box.html;
        $caption-box.render($page);
    }

    if ++$n %% 2 {
        $css.top ➕= 300pt;
        $css.left = 20pt;
    }
    else {
        $css.left ➕= 270pt;
    }
}

done-testing;
