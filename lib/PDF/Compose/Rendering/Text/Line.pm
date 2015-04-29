use v6;

use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Line {

    has $.word-spacing;
    has @.atoms;
    has @.overflow is rw;

    method actual-height { @!atoms.max({ .height }) };
    method actual-width  { @!atoms
                              ?? @!atoms.sum({ .width })  +  $.word-spacing * (+@!atoms - 1)
                              !! 0
    };

}
