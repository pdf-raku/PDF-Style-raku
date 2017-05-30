use v6;

use PDF::Style::Element;

class PDF::Style::Element::Image
    is PDF::Style::Element {

    use HTML::Entity;
    use CSS::Declarations;
    use CSS::Declarations::Units :Scale;

    my class ImageContent {
        has PDF::DAO::Stream $.image handles <width height data-uri>;
        has Numeric  $.x-scale is rw = Scale::px;
        has Numeric  $.y-scale is rw = Scale::px;
        method content-width  { self.width * self.x-scale }
        method content-height { self.height * self.y-scale }
    }
    has ImageContent $.image;

    method place-element( Str:D :$image!, CSS::Declarations :$css!, :$parent-box!) {
        my $width = $parent-box.css-width($css);
        my $height = $parent-box.css-height($css);
        my &content-builder = sub (|c) {
            my \image = ImageContent.new( :image($_) )
                with PDF::Content::Image.open($image);
            die "unable to determine image width" unless image.width;
            die "unable to determine image height" unless image.height;
            if $width {
                image.x-scale = $width / image.width;
                image.y-scale = $height
                    ?? $height / image.height
                    !! image.x-scale;
            }
            elsif $height {
                image.y-scale = $height / image.height;
                image.x-scale = image.y-scale;
            }
            image => image;
        }
        self.place-child-box($css, &content-builder, :$parent-box);
    }

    method render-element($gfx) {
        with $!image {
            my $image = .image;
            my $width = .content-width;
            my $height = .content-height;
            
            $gfx.do($image, :$width, :$height);
        }
    }

    method html {
        my $style = $.css.write;\

        my $style-att = $style
            ?? encode-entities($style).fmt: ' style="%s"'
            !! '';

        with $!image {
            '<img%s src="%s"/>'.sprintf($style-att, .data-uri);
        }
    }

}
