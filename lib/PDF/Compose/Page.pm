use v6;

class PDF::Compose::Page {

    use Font::AFM;
    use PDF::Compose::Units :ALL;
    our %fonts;

    method core-font($font-name, Bool :$bold?, Bool :$italic?) {
        my $class-name = Font::AFM.class-name( $font-name, :$bold, :$italic );
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
