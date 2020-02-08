use v6;
use CSS::Properties::Font;

class PDF::Style::Font
    is CSS::Properties::Font {

    use PDF::Font::Loader;
    method font-obj {
        state %cache;
        my $file = $.find-font;
        %cache{$file} //= PDF::Font::Loader.load-font: :$file;
    }

}
