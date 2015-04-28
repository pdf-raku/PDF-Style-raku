use v6;

use PDF::Compose::Pages;
use Font::AFM;

class PDF::Compose {

    our %fonts;
    has PDF::Compose::Pages $!pages handles <page>;

    method core-font($font-name) {
        %fonts{ $font-name } //= Font::AFM.core-font($font-name);
    }

    submethod BUILD(:$!pages = PDF::Compose::Pages.new ) {
    }
}

