use v6;

class PDF::Style {

    method element(|c) {
        require PDF::Style::Body;
        state $body //= PDF::Style::Body.new: :width(1684), :height(2381);
        $body.element(|c);
    }

    method html-escape(Str $_) {
        .trans:
            /\&/ => '&amp;',
            /\</ => '&lt;',
            /\>/ => '&gt;',
            /\"/ => '&quot;',
    }

}
