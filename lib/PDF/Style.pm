use v6;

module PDF::Style {
    use CSS::Declarations::Units;
    multi sub pt(Numeric $v, Numeric :$em = 12, Numeric :$ex = 9) is export(:pt) {
        (if $v {
                my $units = $v.?key // 'pt';
                my $scale = do given $units {
                    when 'em' { $em }
                    when 'ex' { $ex }
                    default { Units.enums{$units} }
                } or die "unknown units: $units";
                ($v / $scale).Num
            }
         else {
             0
         }) does CSS::Declarations::Units::Keyed["pt"];
    }
    multi sub pt('thick') { pt(5) }
    multi sub pt('medium') { pt(3) }
    multi sub pt('thin') { pt(1) }
    multi sub pt($) is default {Nil}

}
