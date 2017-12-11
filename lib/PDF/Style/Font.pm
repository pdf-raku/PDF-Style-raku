use v6;
use CSS::Declarations::Font;

class PDF::Style::Font
    is CSS::Declarations::Font {

    use PDF::Font::Loader;
    method font-obj {
        state %cache;
        my $file = $.find-font;
        %cache{$file} //= PDF::Font::Loader.load-font: :$file;
    }

}
