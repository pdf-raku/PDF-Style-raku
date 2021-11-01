use v6;

use PDF::Style::Element;

class PDF::Style::Element::HTMLCanvas
    is PDF::Style::Element {

    use CSS::Box;
    use CSS::Properties;
    use PDF::Content::Canvas;
    use PDF::Tags::Elem;

    has Any:D $.html-canvas is required;

    method place-element( :$html-canvas!,
                          CSS::Properties:$css!,
                          CSS::Box :$container!,
                          PDF::Tags::Elem :$tag,
                        ) {
        my &build-content = sub (|) { :$html-canvas };
        nextwith(:$css, :&build-content, :$container, :$tag);
    }

    method render-element($gfx) {
        my PDF::Content::Canvas \image = $gfx.xobject-form: :BBox[0, 0, $.width, $.height];
        image.gfx.draw($!html-canvas);
        image.finish;
        $gfx.do(image, :$.width, :$.height);
    }

    method html {
        my $style = $.css.write;
        $!html-canvas.to-html(:$.width, :$.height, :$style);
    }

}

