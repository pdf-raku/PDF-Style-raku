use v6;

use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Line {

    has $.width;
    has $.word-spacing;

    has PDF::Compose::Rendering::Text::Atom @!atoms;
    has PDF::Compose::Rendering::Text::Atom @.overflow is rw;

    method actual-height { @!atoms.max({ .height }) };
    method actual-width { @!atoms
                              ?? @!atoms.sum({ .width })  +  $.word-spacing * (+@!atoms - 1)
                              !! 0
    };

    submethod BUILD( PDF::Compose::Rendering::Text::Atom :@!atoms,
                     Numeric :$!width?,      #| optional constraint
        ) {
        ...
    }
}
