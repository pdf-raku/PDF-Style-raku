use v6;

use PDF::Content::Text::Line;
use PDF::Content::Text::Atom;

class PDF::Content::Text::Block {
    has Numeric $.line-height;       #| e.g. line-height: 110%  ==>  1.1
    has $.width;
    has $.height;
    has @.lines;
    has @.overflow is rw;
    has $.font-size;

    method actual-width  { @!lines.max({ .actual-width }); }
    method actual-height { @!lines.sum({ .actual-height * ($.line-height || 1) }); }

    submethod BUILD(         :@atoms is copy,
                     Numeric :$word-spacing!,
                     Numeric :$!line-height!,
                     Numeric :$!font-size,
                     Numeric :$!width?,      #| optional constraint
                     Numeric :$!height?,     #| optional constraint
        ) {

        my $line;
        my $line-width = 0.0;

        while @atoms {

            my @word;
            my $atom;

            repeat {
                $atom = @atoms.shift;
                @word.push: $atom;
            } while $atom.sticky && @atoms;

            my $word-width = [+] @word.map({ .width + .space });
            my $trailing-space = @word[*-1].space;

            if !$line || ($!width && $line.atoms && $line-width + $word-width - $trailing-space > $!width) {
                last if $!height && (@!lines + 1)  *  $!line-height > $!height;
                $line = PDF::Content::Text::Line.new();
                $line-width = 0.0;
                @!lines.push: $line;
            }

            $line.atoms.push: @word;
            $line-width += $word-width;
        }

        for @!lines {
            .atoms[*-1].elastic = False;
            .atoms[*-1].space = 0;
        }

        $!width //= self.actual-width;
        $!height //= self.actual-height;

        @!overflow = @atoms;
    }

    method align($mode) {
        .align($mode, :$!width )
            for self.lines;
    }

    method content {

        my @content = $.lines.map({
            (.content(:$.font-size), 'T*' => [])
        });

        @content;
    }

}
