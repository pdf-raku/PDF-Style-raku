use v6;
use Test;
use PDF::Style::Viewport;
use PDF::Style::Element;
use CSS::Declarations;
use CSS::Declarations::Units :pt, :ops;
use PDF::Lite;
use PDF::Content::Image;

# also dump to HTML, for comparision

my PDF::Lite $pdf .= new;
my @Html = '<html>', '<body>';
my ($page, $n); # closure variables

sub test($vp, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone(|$settings);
    my $text = $css.clone(background-image => :url<...>).write;
    warn {:$text}.perl;
    my $elem = $vp.element( :$text, :$css );
    @Html.push: $elem.html;
    $elem.render($page);

    if ++$n %% 2 {
        $base-css.top ➕= 100pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left ➕= 270pt;
    }
}

my $gif = PDF::Content::Image.open("t/images/semitransparent.gif");
my $png = PDF::Content::Image.open("t/images/tiny.png");

for <no-repeat repeat> -> $background-repeat {

    my PDF::Style::Viewport $vp .= new;
    my CSS::Declarations $css .= new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.5); margin: 5pt; padding: 5pt");
    @Html.push: $vp.html-start;

    $page = $vp.add-page($pdf);
    $page.gfx.comment-ops = True;
    $n = 0;

    for [
        { :background-image(:url($gif) ), :$background-repeat,},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<left top>},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<right>},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<right bottom>},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<bottom right>},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<center>},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<15% 25%>},
        { :background-image(:url($gif) ), :$background-repeat, :background-position<10pt 15pt>},
    ] {

        test($vp, $css, $_);
    }

    @Html.push: $vp.html-end;
}

lives-ok {$pdf.save-as: "t/background-position.pdf"};

@Html.append: '</body>', '</html>', '';
"t/background-position.html".IO.spurt: @Html.join: "\n";

done-testing;
