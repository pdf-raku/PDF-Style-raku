use v6;
use CSS::Font;

class PDF::Style::Font
    is CSS::Font {

    use CSS::Font::Resources::Source;
    use PDF::Font::Loader::CSS;
    has PDF::Font::Loader::CSS $!font-loader handles<font-face base-url>;
    use PDF::Font::Loader;
    use PDF::Content::FontObj;
    submethod TWEAK(|c) {
        $!font-loader .= new: |c;
    }
    method font-obj(PDF::Style::Font:D $font:) returns PDF::Content::FontObj {
        state %cache;
        my CSS::Font::Resources::Source $source = $!font-loader.source: :$font;
        my $key = do with $source { .Str } else { '' };
        %cache{$key} //= $!font-loader.load-font: :$font, :$source;
    }

}
