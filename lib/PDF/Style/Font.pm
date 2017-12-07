use v6;
use CSS::Declarations:ver(v0.2.0 .. *);
use CSS::Declarations::Font;

class PDF::Style::Font
    is CSS::Declarations::Font {

    use PDF::Font;
    method font-obj {
        state %cache;
        my $file = $.find-font;
        %cache{$file} //= PDF::Font.load-font: :$file;
    }

}

