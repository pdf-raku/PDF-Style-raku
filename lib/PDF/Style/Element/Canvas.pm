use v6;

use PDF::Style::Element;

class PDF::Style::Element::Canvas
    is PDF::Style::Element {
    use PDF::Style::Font;
    has $.canvas is required;

    method place-element( :$canvas!, :$css!, :$container!) {
        my &build-content = sub (|c) { :$canvas };
        nextwith(:$css, :&build-content, :$container);
    }

    method render-element($gfx) {
        $!canvas.font-object //= PDF::Style::Font.new;
        my \image = $gfx.xobject-form: :BBox[0, 0, $.width, $.height];
        image.gfx.draw($!canvas);
        image.finish;
        $gfx.do(image, :$.width, :$.height);
    }

    method html {
        my $style = $.css.write;
        $!canvas.to-html(:$.width, :$.height, :$style);
    }

}

