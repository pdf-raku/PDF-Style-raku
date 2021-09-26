use v6;
use CSS::Font;

class PDF::Style::Font
    is CSS::Font {

    use PDF::Font::Loader;
    use PDF::Content::FontObj;
    method font-obj returns PDF::Content::FontObj {
        state %cache;
        my $file = $.find-font;
        %cache{$file} //= PDF::Font::Loader.load-font: :$file;
    }

}
