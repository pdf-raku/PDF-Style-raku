use v6;

class PDF::Compose::Page {

    use Font::AFM;
    use PDF::Compose::Units :ALL;
    our %fonts;

    method core-font($font-name is copy, Str :$font-weight?, Str :$font-style?) {

    # font aliases adapted from pdf.js/src/fonts.js
        BEGIN constant stdFontMap = {

          :ArialNarrow<Helvetica>,
          :ArialNarrow-Bold<Helvetica-Bold>,
          :ArialNarrow-BoldItalic<Helvetica-BoldOblique>,
          :ArialNarrow-Italic<Helvetica-Oblique>,

          :ArialBlack<Helvetica>,
          :ArialBlack-Bold<Helvetica-Bold>,
          :ArialBlack-BoldItalic<Helvetica-BoldOblique>,
          :ArialBlack-Italic<Helvetica-Oblique>,

          :Arial<Helvetica>,
          :Arial-Bold<Helvetica-Bold>,
          :Arial-BoldItalic<Helvetica-BoldOblique>,
          :Arial-Italic<Helvetica-Oblique>,

          :ArialMT<Helvetica>,
          :Arial-BoldItalicMT<Helvetica-BoldOblique>,
          :Arial-BoldMT<Helvetica-Bold>,
          :Arial-ItalicMT<Helvetica-Oblique>,

          :Courier-Bold<Courier-Bold>,
          :Courier-BoldItalic<Courier-BoldOblique>,
          :Courier-Italic<Courier-Oblique>,

          :CourierNew<Courier>,
          :CourierNew-Bold<Courier-Bold>,
          :CourierNew-BoldItalic<Courier-BoldOblique>,
          :CourierNew-Italic<Courier-Oblique>,

          :CourierNewPS-BoldItalicMT<Courier-BoldOblique>,
          :CourierNewPS-BoldMT<Courier-Bold>,
          :CourierNewPS-ItalicMT<Courier-Oblique>,
          :CourierNewPSMT<Courier>,

          :Helvetica<Helvetica>,
          :Helvetica-Bold<Helvetica-Bold>,
          :Helvetica-BoldItalic<Helvetica-BoldOblique>,
          :Helvetica-BoldOblique<Helvetica-BoldOblique>,
          :Helvetica-Italic<Helvetica-Oblique>,
          :Helvetica-Oblique<Helvetica-Oblique>,

          :Symbol-Bold<Symbol>,
          :Symbol-BoldItalic<Symbol>,
          :Symbol-Italic<Symbol>,

          :TimesNewRoman<Times-Roman>,
          :TimesNewRoman-Bold<Times-Bold>,
          :TimesNewRoman-BoldItalic<Times-BoldItalic>,
          :TimesNewRoman-Italic<Times-Italic>,

          :TimesNewRomanPS<Times-Roman>,
          :TimesNewRomanPS-Bold<Times-Bold>,
          :TimesNewRomanPS-BoldItalic<Times-BoldItalic>,

          :TimesNewRomanPS-BoldItalicMT<Times-BoldItalic>,
          :TimesNewRomanPS-BoldMT<Times-Bold>,
          :TimesNewRomanPS-Italic<Times-Italic>,
          :TimesNewRomanPS-ItalicMT<Times-Italic>,

          :TimesNewRomanPSMT<Times-Roman>,
          :TimesNewRomanPSMT-Bold<Times-Bold>,
          :TimesNewRomanPSMT-BoldItalic<Times-BoldItalic>,
          :TimesNewRomanPSMT-Italic<Times-Italic>,
        };

        my $bold = $font-weight && $font-weight ~~ m:i/bold|[6..9]00/
            ?? 'Bold' !! '';

        my $italic = $font-style && $font-style ~~ m:i/italic|oblique/
            ?? 'Italic' !! '';

        $font-name = $font-name.subst(/['-'.*]? $/, $bold ~ $italic)
            if $font-weight || $font-style;

        $font-name = stdFontMap{$font-name}
            if stdFontMap{$font-name}:exists;

        my $class-name = Font::AFM.class-name( $font-name );

        %fonts{ $class-name } //= do {
            require ::($class-name);
            ::($class-name).new;
        };
    }

    method text( $text, Hash :$style = {}, Bool :$dry = False) {

        # default HTML font should be Arial
        my $font-family = $style<font-family> // 'helvetica';
        my $font-weight = $style<font-weight> // 'normal';
        my $font-style = $style<font-style> // 'normal';
        my $font-size = $style<font-size> // 16px;

        my $font = self.core-font( $font-family, :$font-weight, :$font-style );

        my $text-width = $font.stringwidth( $text );

        die "can only handle :dry = True"
            unless $dry;

    }
}
