use v6;
use Test;
plan 1;

use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Class;

# also dump to HTML, for comparision

my PDF::Style::Body $body .= new;
my CSS::Properties() $css = "font-family:Helvetica; height:250pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.2)";
my @Html = '<html>', $body.html-start;

my PDF::Class $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment = True;
my $n;

my $image = "t/images/snoopy-happy-dance.jpg";

for [
      { },
      { :background-color<rgba(255,0,0,.2)>, :width(210pt) },
      { :background-color<rgba(255,0,0,.2)>, :border-bottom-style<dashed>, :width<160pt> },
      { :min-width<240pt>, :opacity<.3>, :border("1px solid black") },
      ] {

    test($body, $css, $_, :$image,);
}

my $xobject = $page.gfx.load-image($image);

test($body, $css, {}, :$xobject, :caption('testing of xobject element'));

lives-ok {$pdf.save-as: "t/images.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/images.html".IO.spurt: @Html.join: "\n";

sub test($body, $base-css, $settings = {}, Str :$caption is copy, |c) {
    my $css = $base-css.clone;
    $css.set-properties(|$settings);
    my $elem = $body.element( :$css, |c );
    @Html.push: $elem.html;
    .render($page.gfx, .left, .bottom) with $elem;

    $caption //= ~ CSS::Properties.new: |$settings;
    if $caption {
        my $caption-css = $base-css.clone(
            :border("1pt solid black"),
            :background-color("rgba(200,200,200,.5)"),
           );
        $caption-css.left +css= 8pt;
        $caption-css.width = ($elem.width - 12)pt;
        $caption-css.top = $css.top +css 8pt;
        $caption-css.delete('height');
        my $caption-box = $body.element( :css($caption-css), :text($caption) );
        @Html.push: $caption-box.html;
        .render($page.gfx, .left, .bottom) with $caption-box;
    }

    if ++$n %% 2 {
        $base-css.top +css= 280pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left +css= 260pt;
    }
}

done-testing;
