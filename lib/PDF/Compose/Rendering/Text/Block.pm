use v6;

use PDF::Compose::Rendering::Text::Line;
use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Block {
    has Numeric $.line-height;       #| e.g. line-height: 110%  ==>  1.1
    has $.width;
    has $.height;
    has PDF::Compose::Rendering::Text::Atom @.overflow is rw;

    has PDF::Compose::Rendering::Text::Line @!lines;

    method actual-width  { @!lines.max({ .actual-width }); }
    method actual-height { @!lines.sum({ .actual-height * ($.line-height || 1) }); }

    submethod BUILD( PDF::Compose::Rendering::Text::Atom :@atoms,
                     Numeric :$!width?,      #| optional constraint
                     Numeric :$!height?,     #| optional constraint
        ) {
        ...
    }
}
