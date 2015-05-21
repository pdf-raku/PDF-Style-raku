use v6;
use Test;
use PDF::Compose;
use PDF::Compose::Font;
use PDF::Compose::Units :ALL;
use PDF::Writer;

my $pdf = PDF::Compose.new;

isa_ok $pdf, PDF::Compose, 'PDF::Compose.new';
my $page = $pdf.page(1);
isa_ok $page, ::('PDF::Compose::Page'), 'got first page';

my $helvetica;
#lives_ok { 
$helvetica = PDF::Compose::Font.core-font('Helvetica'); #}, 'core font load - lives';
isa_ok $helvetica, ::('Font::Metrics::helvetica'), 'core font';
is $helvetica.FontName, 'Helvetica', 'font name';
is $helvetica.Weight, 'Medium', 'font weight';

my $tr-bold-italic;
lives_ok { $tr-bold-italic = PDF::Compose::Font.core-font('Times-Roman', :font-weight<bold>, :font-style<italic>); }, 'core font load - lives';
isa_ok $tr-bold-italic, ::('Font::Metrics::times-bolditalic'), 'core font';
is $tr-bold-italic.FontName, 'Times-BoldItalic', 'font name';
is $tr-bold-italic.Weight, 'Bold', 'font weight';
isnt $tr-bold-italic.ItalicAngle, '0', 'italic angle';

my $font-family = 'Helvetica';
my $font-weight = 'bold';
my $width = 300px;
my $font-kerning = 'normal';

for <left center right justify> -> $alignment {
    my $header = [~] '*** ALIGN:', $alignment, ' ***', "\n";
    my $body = q:to"--ENOUGH!!--".subst(/\n/, ' ', :g);
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
        laboris nisi ut aliquip ex ea commodo consequat.
        --ENOUGH!!--

    note "% **** $alignment *** ";
    for $header, $body -> $text {
        my $text-block = $page.text( $text , :style{ :$font-family, :$font-weight, :$width, :$font-kerning });
        $text-block.align( $alignment );

        my $content = $text-block.content;
        note PDF::Writer.write( :$content );
    }
}

done;
