use v6;

#| smallest 'atomic', ie indivisable, unit of text
#| likely to be a word. Could be smaller when kerning.
class PDF::Compose::Rendering::Text::Atom {
    has Numeric $.width;
    has Numeric $.height;
    has Numeric $.kern is rw = 0;       #| kerning, or word spacing adjustment from previous character
    has $.content;

    submethod BUILD( :$!width!, :$!height!, :$!content! ) {
    }

    method split {
        die "can't yet split atoms";
    }
}
