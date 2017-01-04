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
my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.5); background-repeat: no-repeat; margin: 5pt; padding: 5pt");
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

my $jpg = PDF::Content::Image.open("t/images/snoopy-happy-dance.jpg");
my $gif = PDF::Content::Image.open("t/images/semitransparent.gif");

for [   { :background-image(:url($jpg) ) }, { :background-image(:url($jpg) ), :background-color<red> },
        { :background-image(:url($jpg) ), :opacity<.5> },
        { :background-image(:url($jpg) ), :opacity<.5>, :background-color<red> },
        { :background-image(:url($gif) ) },
        { :background-image(:url($gif) ), :opacity<.3>, :background-color<red> },
      ] {

    test($vp, $css, $_);
}

lives-ok {$pdf.save-as: "t/background-image.pdf"};

@Html.append: $vp.html-end, '</body>', '</html>', '';
"t/background-image.html".IO.spurt: @Html.join: "\n";

done-testing;
