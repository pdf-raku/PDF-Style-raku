use Font::AFM;

role PDF::Compose::Font {

    our %fonts;

    method core-font($font-family, Str :$font-weight?, Str :$font-style?) {

    # font aliases adapted from pdf.js/src/fonts.js
        BEGIN constant stdFontMap = {

          :arialnarrow<helvetica>,
          :arialnarrow-bold<helvetica-bold>,
          :arialnarrow-bolditalic<helvetica-boldoblique>,
          :arialnarrow-italic<helvetica-oblique>,

          :arialblack<helvetica>,
          :arialblack-bold<helvetica-bold>,
          :arialblack-bolditalic<helvetica-boldoblique>,
          :arialblack-italic<helvetica-oblique>,

          :arial<helvetica>,
          :arial-bold<helvetica-bold>,
          :arial-bolditalic<helvetica-boldoblique>,
          :arial-italic<helvetica-oblique>,

          :arialmt<helvetica>,
          :arial-bolditalicmt<helvetica-boldoblique>,
          :arial-boldmt<helvetica-bold>,
          :arial-italicmt<helvetica-oblique>,

          :courier-bold<courier-bold>,
          :courier-bolditalic<courier-boldoblique>,
          :courier-italic<courier-oblique>,

          :couriernew<courier>,
          :couriernew-bold<courier-bold>,
          :couriernew-bolditalic<courier-boldoblique>,
          :couriernew-italic<courier-oblique>,

          :couriernewps-bolditalicmt<courier-boldoblique>,
          :couriernewps-boldmt<courier-bold>,
          :couriernewps-italicmt<courier-oblique>,
          :couriernewpsmt<courier>,

          :helvetica<helvetica>,
          :helvetica-bold<helvetica-bold>,
          :helvetica-bolditalic<helvetica-boldoblique>,
          :helvetica-boldoblique<helvetica-boldoblique>,
          :helvetica-italic<helvetica-oblique>,
          :helvetica-oblique<helvetica-oblique>,

          :symbol-bold<symbol>,
          :symbol-bolditalic<symbol>,
          :symbol-italic<symbol>,

          :timesnewroman<times-roman>,
          :timesnewroman-bold<times-bold>,
          :timesnewroman-bolditalic<times-bolditalic>,
          :timesnewroman-italic<times-italic>,

          :timesnewromanps<times-roman>,
          :timesnewromanps-bold<times-bold>,
          :timesnewromanps-bolditalic<times-bolditalic>,

          :timesnewromanps-bolditalicmt<times-bolditalic>,
          :timesnewromanps-boldmt<times-bold>,
          :timesnewromanps-italic<times-italic>,
          :timesnewromanps-italicmt<times-italic>,

          :timesnewromanpsmt<times-roman>,
          :timesnewromanpsmt-bold<times-bold>,
          :timesnewromanpsmt-bolditalic<times-bolditalic>,
          :timesnewromanpsmt-italic<times-italic>,
        };

        my $font-name = $font-family.lc;

        my $bold = $font-weight && $font-weight ~~ m:i/bold|[6..9]00/
            ?? 'bold' !! '';

        # italic & oblique can be treated as synonyms for core fonts
        my $italic = $font-style && $font-style ~~ m:i/italic|oblique/
            ?? 'italic' !! '';

        $font-name = $font-name.subst(/['-'.*]? $/, '-' ~ $bold ~ $italic)
            if $bold || $italic;

        $font-name = stdFontMap{$font-name}
            if stdFontMap{$font-name}:exists;

        my $class-name = Font::AFM.class-name( $font-name );

        %fonts{ $class-name } //= do {
            require ::($class-name);
            ( ::($class-name) but $?ROLE ).new;
        };
    }

    #| css  font-weight classification: 
    method font-weight {
        given self.Weight {
            when 'Normal' || 'Roman' {
                400;
            }
            when 'Bold' | 'Heavy' {
                700;
            }
            default {
                warn "unhandled Weight: $_";
                400;
            }
        }
    }

    #| css  font-style classification: 
    method style {
        given self.FullName {
            when m:s:i/ bold$/   { 'bold' }
            when m:s:i/ oblique$/ { 'oblique' }
            default { 'normal' }
        }
    }

}
