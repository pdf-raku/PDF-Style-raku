use v6;

use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Line {

    has @.atoms;

    method actual-height { @!atoms.max({ .height }) };
    method actual-width  { @!atoms.sum({ .width + .space }) };

}
