use v6;

class PDF::Style {

    method element(|c) {
        require PDF::Style::Viewport;
        state $vp //= PDF::Style::Viewport.new: :width(1684), :height(2381);
        $vp.element(|c);
    }

    method html-escape(Str $_) {
        .trans:
            /\&/ => '&amp;',
            /\</ => '&lt;',
            /\>/ => '&gt;',
            /\"/ => '&quot;',
    }

}
