use v6;
use Test;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Class;
use PDF::Content::XObject;

# also dump to HTML, for comparision

my PDF::Class $pdf .= new;
my @Html = '<html>';
my ($page, $n); # closure variables

sub test($body, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone(|$settings);
    my $text = $css.clone(background-image => :url<...>).write;
    warn {:$text}.perl;
    my $elem = $body.element( :$text, :$css );
    @Html.push: $elem.html;
    .render($page.gfx, .left, .bottom) with $elem;

    if ++$n %% 2 {
        $base-css.top +css= 100pt;
        $base-css.left = 20pt;
    }
    else {
        $base-css.left +css= 270pt;
    }
}

my $gif = PDF::Content::XObject.open("t/images/semitransparent.gif");
my $png = PDF::Content::XObject.open("t/images/tiny.png");

for <no-repeat repeat> -> $background-repeat {

    my PDF::Style::Body $body .= new;
    my CSS::Properties() $css = "font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.5); margin: 5pt; padding: 5pt";
    @Html.push: $body.html-start;

    $page = $body.decorate: $pdf.add-page;
    $page.gfx.comment = True;
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

        test($body, $css, $_);
    }

    @Html.push: $body.html-end;
}

lives-ok {$pdf.save-as: "t/background-position.pdf"};

@Html.append: '</html>', '';
"t/background-position.html".IO.spurt: @Html.join: "\n";

done-testing;
