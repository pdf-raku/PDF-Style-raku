use v6;

use PDF::Style::Element;
use PDF::Style::Font;

class PDF::Style::Element::Canvas
    is PDF::Style::Element {
    has $.canvas is required;

    method place-element( :$canvas!, :$css!, :$parent-box!) {
        my &content-builder = sub (|c) { :$canvas };
        self.place-child-box($css, &content-builder, :$parent-box);
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

