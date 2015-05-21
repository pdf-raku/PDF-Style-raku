use v6;

class PDF::Compose::Page {

    use Font::AFM;
    use PDF::Compose::Units :ALL;
    use PDF::Compose::Rendering::Text::Atom;
    use PDF::Compose::Rendering::Text::Block;
    use PDF::Compose::Font;

    has $.width = 595px;
    has $.height = 842px;

    method text( $text, Hash :$style = {}, Bool :$dry = False) {

        my $position = $style<position> // 'absolute';
        die "sorry can only handle aboslute positioning at the moment"
            unless $position eq 'absolute';
        die "sorry cannot handle bottom positioning yet" if $style<bottom>;
        die "sorry cannot handle right positioning yet" if $style<right>;
        my $left = $style<left> // 0px;
        my $top = $style<top> // 0px;
        my $font-family = $style<font-family> // 'arial';
        my $font-weight = $style<font-weight> // 'normal';
        my $font-style = $style<font-style> // 'normal';
        my $font-size = $style<font-size> // 16px;
        my $width = $style<width> // self.width - $left;
        my $height = $style<height> // self.height - $top;
        my $line-height = $style<line-height> // $font-size * 1.2;

        # todo - see how others handle auto widths & page boundarys
        warn "pushing the boundaries: {:$width} {:$height} {:$top} {:$left}"
            unless $width > 0 && $height > 0 && $left >= 0 && $left < self.width && $top >= 0 && $top < self.height;

        my $font = PDF::Compose::Font.core-font( $font-family, :$font-weight, :$font-style );

        # take word spacing as one space character, for now
        my $word-spacing = $font.stringwidth( ' ', $font-size );

        my $kern = $style<font-kerning>
            && ( $style<font-kerning> eq 'normal'
                 || ($style<font-kerning> eq 'auto' && $font-size <= 32));

        # assume uniform simple text, for now

        my @chunks = $text.split(/<!ww>/)\
            .grep({ $_ ne ''})\
            .map( -> $word {
                $font.encode($word, $font-size, :$kern).map( { { :content(.[0]), :width(.[1]), :space(.[2]) } } )
            });

        my @atoms = @chunks.map({  PDF::Compose::Rendering::Text::Atom.new( |%$_, :$height ) });

        my $text-block = PDF::Compose::Rendering::Text::Block.new( :@atoms, :$word-spacing, :$line-height, :$width, :$height, :$font-size );

        if my $text-align = $style<text-align> {
            $text-block.align( $text-align )
                if $text-align eq 'left' | 'right' | 'center' | 'justify';
        }

        $text-block;
    }
}
