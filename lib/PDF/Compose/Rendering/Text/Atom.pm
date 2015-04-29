use v6;

#| smallest 'atomic', ie indivisable, unit of text
class PDF::Compose::Rendering::Text::Atom {
    has Numeric $.width;
    has Numeric $.height;
    has $.content;

    submethod BUILD( :$!width!, :$!height!, :$!content! ) {
    }

    method split {
        die "can't yet split atoms";
    }
}
