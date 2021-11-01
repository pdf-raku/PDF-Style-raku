use v6;
use Test;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Class;
use PDF::Content::XObject;

# also dump to HTML, for comparision

my PDF::Style::Body $body .= new;
my CSS::Properties() $css = "font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 5px solid rgba(0,128,0,.5); margin: 5pt; padding: 5pt";
my @Html = '<html>', $body.html-start;

my PDF::Class $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
my $n;

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

my $jpg = PDF::Content::XObject.open("t/images/snoopy-happy-dance.jpg");
my $gif = PDF::Content::XObject.open("t/images/semitransparent.gif");
my $png = PDF::Content::XObject.open("t/images/tiny.png");

for [   { :background-image(:url($jpg) ), :background-repeat<no-repeat>, },
        { :background-image(:url($jpg) ), :background-repeat<no-repeat>, :background-color<red> },
        { :background-image(:url($jpg) ), :background-repeat<no-repeat>, :opacity<.5> },
        { :background-image(:url($jpg) ), :background-repeat<no-repeat>, :opacity<.5>, :background-color<red> },
        { :background-image(:url($gif) ), },
        { :background-image(:url($gif) ), :opacity<.3>, :background-color<red> },
        { :background-image(:url($gif) ), :background-position<center> },
        { :background-image(:url($gif) ), :background-position("right top") },
        { :background-image(:url($png) ), :background-color<rgb(20,220,220)>, :color<white> },
        { :background-image(:url($png) ), :background-repeat<repeat-x>, :background-color<rgb(20,220,220)>, :color<white> },
        { :background-image(:url($png) ), :background-repeat<repeat-y>, :background-color<rgb(20,220,220)>, :color<white> },
      ] {

    test($body, $css, $_);
}

lives-ok {$pdf.save-as: "t/background-image.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/background-image.html".IO.spurt: @Html.join: "\n";

done-testing;
