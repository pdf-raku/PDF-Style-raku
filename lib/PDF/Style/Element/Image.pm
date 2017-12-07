use v6;

use PDF::Style::Element;

class PDF::Style::Element::Image
    is PDF::Style::Element {

    use HTML::Entity;
    use CSS::Declarations;
    use CSS::Declarations::Units :Scale;
    use PDF::Content::Image;
    use PDF::Content::XObject;

    our class Content {
        has PDF::Content::XObject $.image handles <width height data-uri>;
        has Numeric  $.x-scale is rw = Scale::px;
        has Numeric  $.y-scale is rw = Scale::px;
        method content-width  { self.width * self.x-scale }
        method content-height { self.height * self.y-scale }
    }
    has Content $.image;

    multi method place-element( Str:D :$image!, |c) {
        my $xobject = PDF::Content::Image.open($image);
        self.place-element( :$xobject, |c);
    }
    multi method place-element( PDF::Content::XObject :$xobject!, CSS::Declarations :$css!, :$parent-box!) {
        my $width = $parent-box.css-width($css);
        my $height = $parent-box.css-height($css);
        my &content-builder = sub (|c) {
            my \image = Content.new( :image($xobject) );
            my \img-width = image.width
                || die "unable to determine image width";
            my \img-height = image.height
                || die "unable to determine image height";

            with $css.min-width {
                $width = $_ if !$width.defined || $width < $_;
            }

            with $css.min-height {
                $height = $_ if !$height.defined || $height < $_;
            }

            if $width {
                image.x-scale = $width / img-width;
                image.y-scale = $height
                    ?? $height / img-height
                    !! image.x-scale;
            }
            elsif $height {
                image.y-scale = $height / img-height;
                image.x-scale = image.y-scale;
            }
            image => image;
        }
        self.place-child-box($css, &content-builder, :$parent-box);
    }

    method render-element($gfx) {
        with $!image {
            my $image  = .image;
            my $width  = .content-width;
            my $height = .content-height;

            $gfx.do($image, :$width, :$height);
        }
    }

    method html {
        my $style = $.css.write;

        my $style-att = $style
            ?? encode-entities($style).fmt: ' style="%s"'
            !! '';

        with $!image {
            '<img%s src="%s"/>'.sprintf($style-att, .data-uri);
        }
    }

}
