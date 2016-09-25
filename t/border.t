use v6;
use Test;
use PDF::Style :pt;
use PDF::Style::Viewport;
use PDF::Style::Box;
use CSS::Declarations;
use CSS::Declarations::Units;
use PDF::Content::PDF;

# also dump to HTML, for comparision

my $css = CSS::Declarations.new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt");
my $vp = PDF::Style::Viewport.new;
my @Html = '<html>', sprintf('<body style="position:relative; width:%dpt; height:%dpt">', $vp.width, $vp.height);

my $pdf = PDF::Content::PDF.new;
my $page = $pdf.add-page;
$page.gfx.comment-ops = True;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ];
my $n;

sub test($vp, $css, $settings = {}, Bool :$feed = True) {
    $css."{.key}"() = .value
        for $settings.pairs;

    my $style = $css.write;
    warn {:$style}.perl;
    my $box = $vp.text( $style, :$css );
    @Html.push: $box.html;
    $box.pdf($page);

    if ($feed) {
        if ++$n %% 2 {
            $css.top += 100pt;
            $css.left = 20pt;
        }
        else {
            $css.left += 270pt;
        }
    }
}

for [ { :border-width(2px), :border-style<solid>, :border-color<red> },
      { :border-width<thick>, :border-style<solid>, :border-color<green> },
      { :border-width<thin>, :border-style<dashed>, :border-color<purple> },
      { :border-width<thin>, :border-style<dotted>, :border-color<blue> },
      { :border-width<3%>, :border-style<dashed>, :border-color<purple> },
      { :border-width<medium>, :border-style<dotted>, :border-top-color<blue>, :border-left-color<green>, :border-bottom-color<yellow>, :border-right-color<red> },
      { :border-width<medium>, :border-style<dotted>, :border-color<rgba(100%,0%,0%,.2)> },
      { :border-width<medium>, :border-style<dotted>, :border-color<hsl(120,100%,50%)> },
      { :padding(5pt), },
      ] {

    test($vp, $css, $_);
}

$css.delete('top');

# do one padded block positioned from the bottom

$css.bottom = $css.height + 30pt;
$css.right = $vp.width - $css.left - $css.width;
$css.delete('left');
test($vp, $css, :!feed);

lives-ok {$pdf.save-as: "t/border.pdf"};

@Html.append: '</body>', '</html>', '';
"t/border.html".IO.spurt: @Html.join: "\n";

done-testing;
