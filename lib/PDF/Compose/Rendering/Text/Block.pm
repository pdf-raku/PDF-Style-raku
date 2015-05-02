use v6;

use PDF::Compose::Rendering::Text::Line;
use PDF::Compose::Rendering::Text::Atom;

class PDF::Compose::Rendering::Text::Block {
    has Numeric $.line-height;       #| e.g. line-height: 110%  ==>  1.1
    has $.width;
    has $.height;
    has @.lines;
    has @.overflow is rw;

    method actual-width  { @!lines.max({ .actual-width }); }
    method actual-height { @!lines.sum({ .actual-height * ($.line-height || 1) }); }

    submethod BUILD(         :@atoms is copy,
                     Numeric :$word-spacing!,
                     Numeric :$!line-height!,
                     Numeric :$!width?,      #| optional constraint
                     Numeric :$!height?,     #| optional constraint
        ) {

        my $line;
        my $line-width = 0.0;

        while @atoms {

            my @word;
            my $word-width = 0.0;
            my $kerning;

            repeat {
                my $atom = @atoms.shift;
                @word.push: $atom;
                $word-width += $atom.width + $atom.space;
                $kerning = $atom.space < 0;
            } while @atoms && $kerning;

            if !$line || ($!width && $line.atoms && $line-width + $word-spacing + $word-width > $!width) {
                last if $!height && (@!lines + 1)  *  $!line-height > $!height;
                $line = PDF::Compose::Rendering::Text::Line.new();
                $line-width = 0.0;
                @!lines.push: $line;
            }

            if $line.atoms {
                $line.atoms[*-1].word-boundary = True;
                $line.atoms[*-1].space += $word-spacing;
                $line-width += $word-spacing
            }

            $line.atoms.push: @word;
            $line-width += $word-width;

        }

        @!overflow = @atoms;
    }

    method align($mode) {
        .align($mode, :$!width )
            for self.lines;
    }
}
