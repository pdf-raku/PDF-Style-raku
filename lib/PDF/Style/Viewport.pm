use v6;

class PDF::Style::Viewport {

    use PDF::Content;
    use PDF::Content::Util::Font;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use PDF::Style :pt;
    use PDF::Style::Box;

    has Numeric $.width = 595pt;
    has Numeric $.height = 842pt;
    has Numeric $.em = 12pt;
    has Numeric $.ex = 9pt;

    method !length($v) {
        pt($v, :$!em, :$!ex);
    }

    method text( Str $text, CSS::Declarations :$css!, Str :$valign is copy) {

        die "sorry cannot handle bottom positioning yet"
            unless $css.bottom eq 'auto';

        my $family = $css.font-family // 'arial';
        my $weight = $css.font-weight // 'normal';
        my $font-style = $css.font-style // 'normal';

        my Numeric $font-size = { :medium(12pt), :large(16pt), :small(9pt) }{$css.font-size} // self!length($css.font-size) // 12pt;
        my $font = PDF::Content::Util::Font::core-font( :$family, :$weight, :style($font-style) );
        $!em = $font-size;
        $!ex = $font-size * $_ / 1000
            with $font.XHeight;

        my $css-top = self!length($css.top) // 0pt;

        my $left = self!length($css.left);
        my $right = self!length($css.right);
        my Numeric $width = $_ with self!length($css.width);
        with self!length($css.max-width) {
            $width = $_
                if !$width.defined || $width > $_;
        }
        with self!length($css.min-width) {
            $width = $_
                if $width.defined && $width < $_;
        }

        my $max-width = $width // self.width - ($left//0) - ($right//0);
        $width //= $max-width if $left.defined && $right.defined;

        my Numeric $height = self!length($css.height) // self.height - $css-top;
        my $line-height = self!length($css.line-height) // $font-size * 1.2;

        my $kern = $css.font-kerning
            && ( $css.font-kerning eq 'normal'
                 || ($css.font-kerning eq 'auto' && $font-size <= 32));

        my $align = $css.text-align && $css.text-align eq 'left'|'right'|'center'|'justify'
            ?? $css.text-align
            !! 'left';

        $valign //= 'top';
        my %opt = :$text, :$font, :$kern, :$font-size, :$line-height, :$height, :$align, :$valign, :width($max-width);
        my $text-block = PDF::Content::Text::Block.new: |%opt;

        $width //= $text-block.actual-width;
        with self!length($css.min-width) -> $min {
            $width = $min if $min > $width
        }
        $left //= $right.defined
            ?? self.width - $right - $width
            !! 0;

        my $top = self!length($.height) - $css-top;
        $height = self!length($css.height) // $text-block.actual-height;
        PDF::Style::Box.new: :$css, :$left, :$top, :$width, :$height, :$!em, :$!ex, :content($text-block);
    }

}
