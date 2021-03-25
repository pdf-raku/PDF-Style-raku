use v6;

use PDF::Style::Element;

class PDF::Style::Element::Canvas
    is PDF::Style::Element {

    use CSS::Box;
    use CSS::Properties;

    has $.canvas is required;

    method place-element( :$canvas!, CSS::Properties:$css!, CSS::Box :$container!) {
        my &build-content = sub (|) { :$canvas };
        nextwith(:$css, :&build-content, :$container);
    }

    method render-element($gfx) {
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

