use v6;

class PDF::Style::Viewport {

    use PDF::Content;
    use PDF::Content::Util::Font;
    use CSS::Declarations;
    use CSS::Declarations::Units;
    use PDF::Style :pt;
    use PDF::Style::Box;

    has $.width = 595pt;
    has $.height = 842pt;

    method text( Str $text, CSS::Declarations :$css!, Str :$valign is copy) {
        my $position = $css.position;
        die "sorry can only handle 'position: absolute' at the moment"
            unless $position ~~ 'absolute';
        die "sorry cannot handle bottom positioning yet"
            unless $css.bottom eq 'auto';
        die "sorry cannot handle right positioning yet"
            unless $css.right eq 'auto';

        my $family = $css.font-family // 'arial';
        my $weight = $css.font-weight // 'normal';
        my $font-style = $css.font-style // 'normal';
        # todo: derive default from the canvas
        my $font-size = pt($css.font-size) // 12pt;
        my $font = PDF::Content::Util::Font::core-font( :$family, :$weight, :style($font-style) );
        my $em = $font-size;
        my $ex = $font-size * $_ / 1000
            with $font.XHeight;

        my $left = pt($css.left, :$em, :$ex) // 0pt;
        my $css-top =pt($css.top, :$em, :$ex) // 0pt;
        my Numeric $width = pt($css.width) // self.width;

        my $height = pt($css.height) // self.height - $css-top;
        my $line-height = pt($css.line-height) // $font-size * 1.2;

        # todo - rtfm on auto widths & page boundarys
        warn "can't cope yet: {:$width} {:$height} {:$css-top} {:$left}"
            unless $width > 0 && $height > 0 && $left >= 0 && $left < self.width && $css-top >= 0 && $css-top < self.height;

        my $kern = $css.font-kerning
            && ( $css.font-kerning eq 'normal'
                 || ($css.font-kerning eq 'auto' && $font-size <= 32));

        my $align = $css.text-align && $css.text-align eq 'left'|'right'|'center'|'justify'
            ?? $css.text-align
            !! 'left';

        $valign //= 'top';
        my $text-block = PDF::Content::Text::Block.new( :$text, :$font, :$kern, :$font-size, :$line-height, :$width, :$height, :$align, :$valign );

        # convert back to pdf coordinates
        my $top = pt($.height) - $css-top;
        $width  = pt($css.width,  :$em, :$ex) // $text-block.actual-width;
        $height = pt($css.height, :$em, :$ex) // $text-block.actual-height;
        my $box = PDF::Style::Box.new: :$css, :$left, :$top, :$width, :$height, :$em, :$ex;

        $text-block, $box;
    }
}
