use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Lite;
use PDF::Content::Image;

# also dump to HTML, for comparision

my $vp = PDF::Style::Viewport.new;
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.5); margin: 5pt; padding: 5pt");
my @Html = '<html>', '<body>', $vp.html-start;

my $pdf = PDF::Lite.new;
my $page = $vp.add-page($pdf);
$page.gfx.comment-ops = True;
my $n;

sub test($vp, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone(|$settings);
    my $text = $css.clone(background-image => :url<...>).write;
    warn {:$text}.perl;
    my $box = $vp.box( :$text, :$css );
    @Html.push: $box.html;
    $box.render($page);

    if ++$n %% 2 {
        $base-css.top += 100pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left += 270pt;
    }
}

my $gif = PDF::Content::Image.open("t/images/semitransparent.gif");
my $png = PDF::Content::Image.open("t/images/tiny.png");

for [
    { :background-image(:url($gif) ), :background-repeat<no-repeat>,},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("left top")},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("right")},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("right bottom")},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("bottom right")},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("center")},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("15% 25%")},
    { :background-image(:url($gif) ), :background-repeat<no-repeat>, :background-position("10pt 15pt")},
    ] {

    test($vp, $css, $_);
}

lives-ok {$pdf.save-as: "t/background-position.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/background-position.html".IO.spurt: @Html.join: "\n";

done-testing;
