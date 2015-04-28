use v6;

use PDF::Compose::Pages;
use Font::AFM;

class PDF::Compose {

    our %fonts;
    has PDF::Compose::Pages $!pages handles <page>;
    method core-font($font-name, Bool :$bold?, Bool :$italic?) {
        my $class-name = Font::AFM.class-name( $font-name, :$bold, :$italic );
        %fonts{ $class-name } //= do {
            require ::($class-name);
            ::($class-name).new;
        };
    }

    submethod BUILD(:$!pages = PDF::Compose::Pages.new ) {
    }
}

