use v6;

class PDF::Compose::Page {

    use Font::AFM;
    use PDF::Compose::Units :ALL;
    use PDF::Compose::Rendering::Text::Atom;
    use PDF::Compose::Rendering::Text::Block;
    our %fonts;

    has $.width = 595px;
    has $.height = 842px;

    method core-font($font-name is copy, Str :$font-weight?, Str :$font-style?) {

    # font aliases adapted from pdf.js/src/fonts.js
        BEGIN constant stdFontMap = {

          :arialnarrow<helvetica>,
          :arialnarrow-bold<helvetica-bold>,
          :arialnarrow-bolditalic<helvetica-boldoblique>,
          :arialnarrow-italic<helvetica-oblique>,

          :arialblack<helvetica>,
          :arialblack-bold<helvetica-bold>,
          :arialblack-bolditalic<helvetica-boldoblique>,
          :arialblack-italic<helvetica-oblique>,

          :arial<helvetica>,
          :arial-bold<helvetica-bold>,
          :arial-bolditalic<helvetica-boldoblique>,
          :arial-italic<helvetica-oblique>,

          :arialmt<helvetica>,
          :arial-bolditalicmt<helvetica-boldoblique>,
          :arial-boldmt<helvetica-bold>,
          :arial-italicmt<helvetica-oblique>,

          :courier-bold<courier-bold>,
          :courier-bolditalic<courier-boldoblique>,
          :courier-italic<courier-oblique>,

          :couriernew<courier>,
          :couriernew-bold<courier-bold>,
          :couriernew-bolditalic<courier-boldoblique>,
          :couriernew-italic<courier-oblique>,

          :couriernewps-bolditalicmt<courier-boldoblique>,
          :couriernewps-boldmt<courier-bold>,
          :couriernewps-italicmt<courier-oblique>,
          :couriernewpsmt<courier>,

          :helvetica<helvetica>,
          :helvetica-bold<helvetica-bold>,
          :helvetica-bolditalic<helvetica-boldoblique>,
          :helvetica-boldoblique<helvetica-boldoblique>,
          :helvetica-italic<helvetica-oblique>,
          :helvetica-oblique<helvetica-oblique>,

          :symbol-bold<symbol>,
          :symbol-bolditalic<symbol>,
          :symbol-italic<symbol>,

          :timesnewroman<times-roman>,
          :timesnewroman-bold<times-bold>,
          :timesnewroman-bolditalic<times-bolditalic>,
          :timesnewroman-italic<times-italic>,

          :timesnewromanps<times-roman>,
          :timesnewromanps-bold<times-bold>,
          :timesnewromanps-bolditalic<times-bolditalic>,

          :timesnewromanps-bolditalicmt<times-bolditalic>,
          :timesnewromanps-boldmt<times-bold>,
          :timesnewromanps-italic<times-italic>,
          :timesnewromanps-italicmt<times-italic>,

          :timesnewromanpsmt<times-roman>,
          :timesnewromanpsmt-bold<times-bold>,
          :timesnewromanpsmt-bolditalic<times-bolditalic>,
          :timesnewromanpsmt-italic<times-italic>,
        };

        $font-name = $font-name.lc;

        my $bold = $font-weight && $font-weight ~~ m:i/bold|[6..9]00/
            ?? 'bold' !! '';

        my $italic = $font-style && $font-style ~~ m:i/italic|oblique/
            ?? 'italic' !! '';

        $font-name = $font-name.subst(/['-'.*]? $/, '-' ~ $bold ~ $italic)
            if $bold || $italic;

        $font-name = stdFontMap{$font-name}
            if stdFontMap{$font-name}:exists;

        my $class-name = Font::AFM.class-name( $font-name );

        %fonts{ $class-name } //= do {
            require ::($class-name);
            ::($class-name).new;
        };
    }

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

        my $font = self.core-font( $font-family, :$font-weight, :$font-style );

        # take word spacing as one space character, for now
        my $word-spacing = $font.stringwidth( ' ', $font-size );

        my $do-kerning = $style<font-kerning>
            && ( $style<font-kerning> eq 'normal'
                 || ($style<font-kerning> eq 'auto' && $font-size <= 32));

        # assume uniform simple text, for now

        my @words = $text.split(/\s+/).grep({ $_ ne ''});

        my @chunks = @words.map( -> $word {
            $do-kerning
                ?? $font.kern($word, $font-size).map( { { :content(.[0]), :width(.[1]), :space(.[2]) } } )
                !! { :content($word), :width( $font.stringwidth( $word, $font-size ) ), :space(0) }
        });

        my @atoms = @chunks.map({  PDF::Compose::Rendering::Text::Atom.new( |%$_, :height($font-size) ) });

        my $text-block = PDF::Compose::Rendering::Text::Block.new( :@atoms, :$word-spacing, :$line-height, :$width, :$height );

        $text-block;
    }
}
