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

my $css = CSS::Declarations.new: :style("font-family:Helvetica; height:60pt; position:absolute; top:10pt; left:10pt; border: 1pt solid red");
my $vp = PDF::Style::Viewport.new;

my $pdf = PDF::Content::PDF.new;
my $page = $pdf.add-page;
$page.gfx.comment-ops = True;
$page.media-box = [0, 0, pt($vp.width), pt($vp.height) ];
my $n;

constant %Width = %('_' => Mu, '-' => 200pt, '=' => 250pt, '+' => 300pt);

my %seen;

for [ '_=_' => '=',
      '-_+' => '+',
      '+=-' => '+',
      '-+=' => '=',
      '_+=' => '=',
      '+=_' => '+',
      '_=+' => '=',
      '+_=' => '+',
      '-__' => 'long',
      '___' => 'long',
    ] {
    warn "duplicate test: {.key}" if %seen{.key}++;
    my ($min-width, $width, $max-width) = .key.comb.map: { %Width{$_} };
    my $expected-width = .value;

    $css.delete($_) for <width min-width max-width>;
    $css.min-width = $_ with $min-width;
    $css.width = $_ with $width;
    $css.max-width = $_ with $max-width;

    my $style = $css.write;
    my $box = $vp.text( (++$n,.value, ':', .key, $style).join(' '), :$css );
    @html.push: $box.html;
    $page.graphics: {
        $box.style($_);
        $page.text: {
            my $left = $box.left;
            my $top = $box.top;
            .print($box.content, :position[:$left, :$top]);
        }
    }
    my $box-width = $box.right - $box.left;
    if $expected-width eq 'long' {
        ok $box-width > 400pt, 'box width';
    }
    else {
        is-approx $box-width, %Width{$expected-width}, 'box width';
    }
##    if ++$n %% 2 {
        $css.top += 75pt;
##        $css.left = 20pt;
##    }
##    else {
##        $css.left += 270pt;
##    }
}

lives-ok {$pdf.save-as: "t/widths.pdf"};

@html.append: '</body>', '</html>', '';
"t/widths.html".IO.spurt: @html.join: "\n";

done-testing;
