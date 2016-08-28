use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $css = CSS::Declarations.new: :style("font-family:Helvetica; height:30pt; width:110pt; position:absolute; top:10pt; left:10pt; right:10pt; border:1pt solid red;");
my $Vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
my $Page = $pdf.add-page;
$Page.gfx.comment-ops = True;
$Page.media-box = [0, 0, pt($Vp.width), pt($Vp.height) ];
my @Html = '<html>', sprintf('<body style="position:relative; width:%dpt; height:%dpt">', $Vp.width, $Vp.height);
my $N;

sub show-text($text, :$css!) {
    warn { :$text, :style($css.write) }.perl;
    my $box = $Vp.text( $text, :$css );
    @Html.push: $box.html;

    $box.pdf($Page);
    if ++$N %% 5 {
        $css.top += 35pt;
        $css.left = 10pt;
    }
    else {
        $css.left += 115pt;
    }
}

$Vp.block: {
    for <courier helvetica times-roman> -> $font-family {
        $css.font-family = :ident($font-family);
        for <normal bold> -> $font-weight {
            $css.font-weight = :keyw($font-weight);
            for <normal italic> -> $font-style {
                $css.font-style = :keyw($font-style);
                show-text("font: $font-style $font-weight $font-family", :$css);
            }
        }
    }
}

$Vp.block: {
    for 300, 400 ... 900 -> $num {
        $css.font-weight = :$num;
        show-text("font-weight: $num", :$css);
    }

    $css.font-weight = :keyw<lighter>;
    for (1..5)  { show-text("font-weight: lighter", :$css); }

    $css.font-weight = :keyw<bolder>;
    for (1..5)  { show-text("font-weight: bolder", :$css); }
}

$Vp.block: {
    for <x-small small medium large x-large> -> $keyw {
        $css.font-size = :$keyw;
        show-text("font-size: $keyw", :$css);
    }
    for 10, 12 -> $pt {
        $css.font-size = :$pt;
        show-text("font-size: {$pt}pt", :$css);
    }
    for 'smaller' xx 3 -> $keyw {
        $css.font-size = :$keyw;
    }
}

lives-ok {$pdf.save-as: "t/fonts.pdf"};

@Html.append: '</body>', '</html>', '';
"t/fonts.html".IO.spurt: @Html.join: "\n";

done-testing;
