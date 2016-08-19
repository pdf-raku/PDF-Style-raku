use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my @html = '<html>', '<body style="position:relative">';

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt");
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
my $page = $pdf.add-page;
$page.gfx.comment-ops = True;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ];
my $n;

for [ { :width(:px(2)), :style( :keyw<solid> ), :color<red> },
      { :width(:keyw<thick>), :style( :keyw<solid>), :color<green> },
      { :width(:keyw<thin>) , :style( :keyw<dashed> ), :color<purple> },
      { :width(:keyw<thin>) , :style( :keyw<dotted> ), :color<blue> },
      { :width(:keyw<medium>) , :style( :keyw<dotted> ), :top-color<blue>, :left-color<green>, :bottom-color<yellow>, :right-color<red> },
      ] -> $border {

    for $border.pairs {
        my $v = .value;
        $v := 'color' => $v
            if .key ~~ /'color'/ && .value.isa(Str);
        $css."border-{.key}"() = $v;
    }

    my $style = $css.write;
    my $width = $css.width; warn {:$width, :$style}.perl;
    my $box = $vp.text( $style, :$css );
    @html.push: $box.html;
    $page.graphics: {
        $box.style($_);
        $page.text: {
            my $left = $box.left;
            my $top = $box.top;
            .print($box.content, :position[:$left, :$top]);
        }
    }
    if ++$n %% 2 {
        $css.top += 100pt;
        $css.left = 20pt;
    }
    else {
        $css.left += 270pt;
    }
}

lives-ok {$pdf.save-as: "t/border.pdf"};

@html.append: '</body>', '</html>', '';
"t/border.html".IO.spurt: @html.join: "\n";

done-testing;
