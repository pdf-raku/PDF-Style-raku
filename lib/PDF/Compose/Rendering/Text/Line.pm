use v6;

use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Line {

    has @.atoms;
    has Numeric $.indent is rw = 0;

    method actual-height { @!atoms.max({ .height }) };
    method actual-width  { [+] @!atoms.map({ .width + .space }) };

    multi method align('justify', Numeric :$width! ) {
        my $actual-width = $.actual-width;

        if $width > $actual-width {
            my @word-boundarys = @!atoms.grep({.word-boundary});

            if +@word-boundarys {
                my $adjustment = ($width - $actual-width) / +@word-boundarys;
                .space += $adjustment
                    for @word-boundarys;
            }
        }
    }

    multi method align('left', Numeric :$width! ) {
        $.indent = 0;
    }

    multi method align('right', Numeric :$width! ) {
        $.indent = $width - $.actual-width;
    }

    multi method align('center', Numeric :$width! ) {
        $.indent = ( $width - $.actual-width )  /  2;
    }

}
