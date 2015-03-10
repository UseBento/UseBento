function get_tco_token() {
    var payload = {sellerId:        $('#seller_id').val(),
                   publishableKey:  $('#publishable_key').val(),
                   ccNo:            $('#credit-card-number').val(),
                   expMonth:        $('#expr-date-month').val(),
                   expYear:         $('#expr-date-year').val(),
                   cvv:             $('#cvv').val()};

    TCO.loadPubKey($('#twocheckout_type').val(), function() {
        function success(response) {
            $('#twocheckout-token').val(response.response.token.token)
            $('#twocheckout-payment-method')
                .val(JSON.stringify(response.response.paymentMethod));
            $('#tco-form')[0].submit(); }

        function failure() {
            console.log(['failure', arguments]); }

        TCO.requestToken(success, failure, payload); }); }

function setup_paypal_direct() {
    $('#paypal-name').val($('#field-fname').val() + ' ' + $('#field-lname').val());
    $('#paypal-addr').val($('#field-addr').val());
    $('#paypal-addr2').val($('#field-addr2').val());
    $('#paypal-city').val($('#field-city').val());
    $('#paypal-state').val($('#field-state').val());
    $('#paypal-country').val($('#field-country').val());
    $('#paypal-zip').val($('#field-zip').val());
    $('#paypal-email').val($('#field-email').val());
    $('#paypal-phone').val($('#field-phone').val());

    $('#tco-form').attr('action', 'https://www.2checkout.com/checkout/purchase');
    $('#tco-form')[0].submit(); }

(function($, window, document, undefined) {
    var $win = $(window);
    var $doc = $(document);

    $doc.ready(function() {
        $('#tco-form').submit(function(event) {
            event.preventDefault();
            if ($('#paypal').prop('checked'))
                setup_paypal_direct();
            else
                get_tco_token(); });

        var waiting_for_login   = false;
        var signed_in           = false;
        var just_submit_project = true;

        $('#project-popup')
            .magnificPopup({type: 'ajax'})
            .click();

        function sign_up(event) {
            event.preventDefault();
            var form       = $('#sign-up-form');
            var name       = $('#sign-up-form #field-name').val();
            var email      = $('#sign-up-form #field-email-address').val();
            var password   = $('#sign-up-form #field-password').val();
            var company    = $('#sign-up-form #field-company-name').val();

            $.ajax({type: 'POST',
                    url:  '/users/sign_up.json',
                    data: {name:      name,
                           email:     email,
                           password:  password,
                           company:   company},
                    success: function(data) {
                        if (data.error)
                            $('#sign-up-errors').html(data.error);
                        else {
                            if (waiting_for_login)
                                waiting_for_login();
                            else
                                window.location.href = '/'; }}}); }

        function log_in(event) {
            event.preventDefault();
            var form       = $('#log-in-form');
            var email      = $('#log-in-form #field-email').val();
            var password   = $('#log-in-form #field-password').val();

            $.ajax({type: 'POST',
                    url:  '/users/log_in.json',
                    data: {email:      email,
                           password:   password},
                    success: function(data) {
                        if (data.error)
                            $('#log-in-errors').html(data.error);
                        else {
                            if (waiting_for_login)
                                waiting_for_login();
                            else {
                                if (window.location.pathname == "/")
                                    window.location.href = "/projects/list";

                                $('#userlink')
                                    .attr('href', '/profile')
                                    .attr('data-userid', data.id)
                                    .html('PROFILE');
                                $.magnificPopup.close();

                                $('a[href="/agencies"]')
                                    .html('PROJECTS')
                                    .attr('href', '/projects/list');

                                $('a[href="/apply"]')
                                    .css('display', 'none');

                                if (window.location.pathname != "/projects/start") {
                                    $('#field-full-name')
                                        .val(data.username)
                                        .attr('type', 'hidden')
                                        .parent().append(data.username);

                                    $('#field-e-mail')
                                        .val(data.email)
                                        .attr('type', 'hidden')
                                        .parent().append(data.email);

                                    var company = $('#field-name-business');
                                    if (!company.val())
                                        company.val(data.company);

                                    var target = $('#field-target');
                                    if (!target.val())
                                        target.val(data.audience);

                                    var keywords = $('#field-keywords');
                                    if (!keywords.val())
                                        keywords.val(data.keywords); }}}}}); }

        function reset_password(event) {
            event.preventDefault();
            var form       = $('#password-reset-form');
            var email      = $('#password-reset-form #field-email').val();

            $.ajax({type: 'POST',
                    url:  '/users/reset.json',
                    data: {email:      email},
                    success: function(data) {
                        if (data.error)
                            $('#password-errors').html(data.error);
                        else
                            $('#sent-link').click(); }}); }

        function counter($element) {
            var $field = $element.find('.counter-field');
            var value = parseInt($field.val());
            var setValue = function(newVal) {
            value = Math.max(1, newVal);

            $field.val(value).trigger('change');
            };

            $element
            .off('click.counter')
            .on('click.counter', '.counter-control-minus', function() {
                setValue(value - 1)
            })
            .on('click.counter', '.counter-control-plus', function() {
                setValue(value + 1); }); };

        function add_message(message_body, id) {
            var message       = $('#message-box').val();
            if ($('li.project-message[data-id="' + id + '"]')[0])
                return;

            var message_li = $('<div/>');
            message_li.html(message_body);
            message_li.insertBefore($('li#message-form-li'));

            link_message_buttons();
            reset_message_form(); }

        function project_chatroom() {
            return $('#chat-room').val(); }

        function inc_other_unread_count() {
            var tag    = $('span.unread-tag');
            var count  = parseInt(tag.html());
            tag.html(count + 1);
            tag.attr('data-count', count + 1); }

        var channel;
        var dispatcher;
        function messages_websocket() {
            var room         = project_chatroom();
            var other_room   = room == 'private' ? 'group' : 'private';
            var project_id   = $('#project-id').val();
            var socket_url   = (window.location.host == window.location.hostname
                                ? window.location.hostname + ":3001/websocket"
                                : window.location.host + "/websocket");

            function connect_socket() {
            dispatcher       = new WebSocketRails(socket_url);
            dispatcher.on_open = function(data) {
                channel          = dispatcher.subscribe('project-' + project_id);

                channel.bind('message_posted', function(message) {
                    if (message.room != room) {
                        inc_other_unread_count(); }
                    else {
                        var id    = message.message_id;
                        var pid   = message.project_id;
                        if (pid != project_id) return;

                        $.ajax(
                            {type: 'get',
                             url: '/projects/' + pid + '/message/' + id + '.json',
                             success: function(data) {
                                 add_message(data.body, data.id); }}); }});

                channel.bind('message_updated', function(message) {
                    var id    = message.message_id;
                    var pid   = message.project_id;
                    var el    = $('li.project-message[data-id="' + id + '"]');
                    if (pid != project_id || !el) return;

                    $.ajax(
                        {type: 'get',
                         url: '/projects/' + pid + '/message/' + id + '.json',
                         success: function(data) {
                             el.html(data.body);
                             el.attr('data-processed', null);
                             link_message_buttons();
                             reset_message_form(); }}); });

                channel.bind('message_removed', function(message) {
                    var id    = message.message_id;
                    var pid   = message.project_id;
                    var el    = $('li.project-message[data-id="' + id + '"]');
                    if (pid != project_id || !el) return;
                    el.detach(); });

                channel.bind('new_message', function(message) {
                    if (!$('li.project-message[data-id="' + message.id + '"]')[0])
                        add_message(message.body, message.id); }); };

                setTimeout(function() {
                    if (dispatcher.state == "disconnected")
                        connect_socket(); },
                           3000); }

            connect_socket(); }

        if ($('#message-box') && $('#project-id').val())
            messages_websocket();

        function submit_project_message(event) {
            event.preventDefault();
            var message       = $('#message-box').val();
            var project_id    = $('#project-id').val();
            var chatroom      = project_chatroom();

            function success(data) {
                if (progress_bar)
                    progress_bar.css('display', 'none');

                try {
                    channel.trigger('message_posted',
                                    {message_id:  data.id,
                                     room:        project_chatroom(),
                                     project_id:  project_id}); }
                catch (e) {}

                add_message(data.body);
                $('#message-box').val($('#message-box')[0].defaultValue); }

            var data = {message_body: message};
            data     = new FormData($('#message-form')[0]);

            if (!message_form_has_data())
                return;

            var progress_bar = $('input[name^="file-upload-"]')[0] && $('#progress-bar');
            if (progress_bar) {
                progress_bar.css('display', 'block');
                progress_bar.progressbar({value: 0}); }

            function upload_progress(evt) {
                if (evt.lengthComputable)
                    progress_bar.progressbar({value: ((evt.loaded / evt.total)
                              * 85)}); }
            function response_progress(evt){
                if (evt.lengthComputable)
                    progress_bar.progressbar({value: (85 + ((evt.loaded / evt.total)
                                * 15))}); }
            $.ajax({type: 'POST',
                    xhr: function() {
                        var xhr = new window.XMLHttpRequest();
                        if (progress_bar) {
                            xhr.upload.onprogress    = upload_progress;
                            xhr.onprogress           = response_progress; }
                        return xhr; },
                    url:          '/projects/' + project_id + '/message.json',
                    data:          data,
                    enctype:      'multipart/form-data',
                    processData:   false,
                    contentType:   false,
                    success:       success}); }

        function reset_message_form() {
            $('input[name^="file-upload-"], .file-upload-container').map(
                function(i,input) {
                    $(input).remove(); }); };

        function message_form_has_data() {
            return $('input[type="file"][id^="file-upload-"]').length > 0
                || $('#message-box').val() != ""; }

        function set_add_comment_state(reset) {
            var has_data = message_form_has_data();
            if (reset !== undefined)
                has_data = !reset;
            $('.cancel_btn').css('display', has_data ? 'inline' : 'none');
            $('#add-comment').prop('disabled', !has_data); }

        $('#message-form').submit(submit_project_message);
        $('#message-form').bind('reset', reset_message_form);
        $('#message-box').change(curry(set_add_comment_state, false));
        $('#message-box').keydown(curry(set_add_comment_state, false));
        $('.cancel_btn').click(curry(set_add_comment_state, true));

        var file_upload_id = 1;
        $('#file-link').click(function(event) {
            event.preventDefault();
            var file_upload = $('#file-upload');
            file_upload.change(function() {
                var container, parent;
                file_upload.css('display', 'inline-block');
                file_upload.attr('id', 'file-upload-' + file_upload_id.toString());
                file_upload.attr('name', 'file-upload-' + file_upload_id.toString());

                parent = $('.attachment_box');
                file_upload.detach();
                function remove_file_upload() {
                    container.detach(); }

                container = build_el(
                    div('file-upload-container',
                        [file_upload,
                         ' ',
                         a('clear-file-upload', ['x'],
                           remove_file_upload)]));
                parent.append(container);

                parent.append(
                    build_el(input({id:    'file-upload',
                                    type:  'file',
                                    style: 'display:none'})));
                file_upload_id++;
                set_add_comment_state(); });
            file_upload.trigger('click'); });

        $('#upload-btn').click(function(event) {
            var file_upload = $('#file-upload');
            file_upload.change(function() {
                function remove_file() {
                    file_upload.detach();
                    file_icon.detach(); }

                var filename    = file_upload.val().match(/[^\\]+$/)[0];
                var file_icon   = build_el(
                    div('attachment',
                        [i('fa fa-paperclip paperclip'),
                         i('close-link fa fa-times', [], remove_file),
                         div('label', [filename])]));
                $('#uploading-files').append(file_icon);

                file_upload.attr('id', 'file-upload-' + file_upload_id.toString());
                file_upload.attr('name', 'file-upload-' + file_upload_id.toString());
                file_upload.parent().append(
                    build_el(input({id:    'file-upload',
                                    type:  'file',
                                    style: 'display:none'})));
                file_upload_id++; });
            file_upload.trigger('click'); });


        function check_first() {
            if ($('#editing')[0]) return;
            var radios = $.unique($('input[type="radio"]')
                                  .map(function(i, j) {
                                      return j.name; }));
            radios.map(function(i, name) {
                var inputs = $('input[type="radio"][name="' + name + '"]');
                $(inputs[0]).prop('checked', true); }); }

        function current_user() {
            var user_link = $('#userlink');
            var user_id   = user_link.attr('data-userid');
            var name      = user_link.html();

            return (user_id
                    ? {id:     user_id,
                       name:   name}
                    : false); }

        window.cart = new Cart();

        counter($('.counter-input'));
        check_first();

        $('.intro-bg').fullscreener();
        $('.select').selectbox();

        function log_in_then(next) {
            if (current_user())
                next();
            else {
                waiting_for_login = next;
                $('#userlink').click(); }}

        function setup_project_form() {
            var project_form     = $('#project-form');
            var project_submit   = $('#project-submit');

            if (project_form) {
                just_submit_project = false;
                project_form.submit(function(event) {
                    if (just_submit_project)
                        return true;
                    else {
                        event.preventDefault();
                        return check_user_exists(
                            $('#field-e-mail').val(),
                            function() {
                                log_in_then(function() {
                                    just_submit_project = true;
                                    project_form.submit(); }); },
                            function() {
                                just_submit_project = true;
                                project_form.submit(); }); }}); }}

        setup_project_form();

        function check_user_exists(email, if_exists, otherwise) {
            $.ajax({type:    'GET',
                    url:     '/user_exists.json?email=' + encodeURIComponent(email),
                    success:  function(data) {
                        return data.exists
                            ? if_exists()
                            : otherwise(); }}); }


        function update_price() {
            var button         = $('#project-submit');
            var price          = parseInt($('#page-price').val());
            var page_counter   = $('#pages-count');
            var page_count     = (page_counter ? page_counter.val() : 1) || 1;
            var responsive     = $('#field-desktop-mobile').prop('checked');
            var plus_dev       = $('#field-design-development').prop('checked');
            var responsive_price     = $('#responsive-price').val() || price;
            var plus_dev_price       = $('#plus-dev-price').val() || price;

            if ($('input[name="service_name"]').val() == 'social_media_design')
                page_count = $('input.header-type')
                    .map(function(i, ii) {
                        return $(ii).prop('checked'); })
                    .filter(function(i, x) {
                        return x; }).length;

            if (price === 0) return;
            if (plus_dev)
                if (plus_dev_price)
                    price = plus_dev_price;
            if (responsive) {
                if (responsive_price)
                    price = responsive_price;
                else
                    price += 20; }

            price = price * page_count;
            button.html('GET STARTED - $' + price); }

        function update_development_type_visibility() {
            if ($('#field-design-development').prop('checked')) {
                $('#development-type').css('visibility', 'visible'); }
            else {
                $('#development-type').css('visibility', 'hidden');
                $('#field-desktop-only').prop('checked', true); }}


        $('#pages-count').change(update_price);
        $('.header-type').change(update_price);
        $('#field-desktop-mobile, #field-desktop-only, #field-design-development, #field-design-only')
            .change(o(update_price,
                      update_development_type_visibility));

        $('#projects-list').tablesorter({sortList: [[0,0]]});
//        $('#projects-list thead .tbl_row td:first-child').click();

        $('#invite-coworkers').click(function() {
            $('#enter-invite').removeClass('hidden');
            $('#invite-coworkers').addClass('hidden'); });

        $('#submit-invite').click(function() {
            var email    = $('#enter-email').val();
            var id       = $('#project-id').val();
            var chat     = $('#chat').val();
            var url      = ('/projects/' + id + '/'
                            + (chat == 'group' ? '' : 'private/')
                            + 'invite.json');

            $.ajax({type:    'POST',
                    url:      url,
                    data:    {email: email},
                    success:  function(data) {
                        if (data.error)
                            return $('#invite-errors').html(data.error);
                        $('#invite-errors').html('');

                        var row = build_el(
                            div('people-entry col_four',
                                [img({'class':  "avatar",
                                      src:      ('/images/avatars/' +
                                                 email[0].toUpperCase() + '.png'),
                                      alt:      ''}),
                                 span('', [data.email]),
                                 span('invite-sent', ['Invite Sent'])]));
                        $('#people').append(row);

                        $('#enter-email').val('');
                        $('#enter-invite').addClass('hidden');
                        $('#invite-coworkers').removeClass('hidden'); }}); });

        function save_message(message_id) {}

        function edit_message(message_id) {
            var message_el    = $('li.project-message[data-id="' + message_id + '"]');
            var pencil        = message_el.find('.edit-message');
            var wrapper       = message_el.find('.content-wrapper');
            var message_text  = message_el.find('.message-content');
            var message_raw   = message_el.find('.message-content .raw_content');
            var edit_area     = build_el(textarea({'class':   'message-content-editing text_box',
                                                   rows:       5},
                                                  [message_raw.html()]));
            var btn           = build_el(button({type:    'button',
                                                 'class': 'btn btn-sm right message-save-button'},
                                                ['Save'],
                                                curry(save_message, message_id)));

            message_text.detach();
            wrapper.append(edit_area);
            wrapper.append(btn);
            pencil.css('display', 'none');

            function update_message() {
                $.ajax({type:     'POST',
                        url:      '/projects/update_message.json',
                        data:     {id:           message_id,
                                   new_message:  edit_area.val(),
                                   project_id:   $('#project-id').val()},

                        success:  function(data) {
                            pencil.css('display', 'block');
                            edit_area.detach();
                            message_raw.detach();
                            btn.detach();
                            message_text.html(data.body);
                            message_raw.html(data.raw);
                            message_text.append(message_raw);
                            wrapper.append(message_text);

                            try {
                                channel.trigger('message_updated',
                                                {message_id: message_id,
                                                 project_id: $('#project-id').val()}); }
                            catch (e) {
                                // fail gracefully if socket disconnected or
                                // channel.trigger fails
                            }}}); }

            btn.click(update_message); }

        function remove_message(message_id) {
            $.ajax({type:     'POST',
                    data:     {id:          message_id,
                               project_id:  $('#project-id').val()},
                    url:      '/projects/delete_message.json',
                    success:  function(data) {
                        try {
                            channel.trigger('message_removed',
                                            {message_id: message_id,
                                             project_id: $('#project-id').val()}); }
                        catch (e) {
                            // fail gracefully if socket disconnected or
                            // channel.trigger fails
                        }

                        $('li.project-message[data-id="' + message_id + '"]')
                            .detach();
                        $.magnificPopup.close(); }}); }

        function link_message_buttons() {
            $('li.project-message').map(function(i, li) {
                li = $(li);
                var id = li.attr('data-id');
                if (li.attr('data-processed')) return;

                li.find('.delete-message').magnificPopup();
                li.find('.close-delete-message').click($.magnificPopup.close);
                li.find('.confirm-delete-message').click(curry(remove_message, id));

                li.find('.edit-message').click(curry(edit_message, id));
                li.attr('data-processed', 'true'); }); }

        link_message_buttons();

        function close_popup() {
            $.magnificPopup.close(); }

        function ask_are_you_sure(el, next, message, title) {
            title       = title || "Are you sure?";
            message     = message || "Are you sure you want to do this?";
            var id      = "id-" + Math.random().toString().slice(2);
            var popup   = build_el(
                div({'class': 'delete-popup mfp-hide',
                     id:      id},
                    [div('access',
                         [div('form form-access',
                              [form('',
                                    [div('popup-body',
                                         [div('form-head',
                                              [h2('', [title])]),
                                          div('form-body',
                                              [center(
                                                  '',
                                                  [message, br(), br(),
                                                   button({'class': 'btn gray',
                                                           style:   'margin-right:0.7em;',
                                                           type:    'button'},
                                                          ['Cancel'],
                                                          close_popup),
                                                   ' ',
                                                   button({'class': 'btn',
                                                           type:    'button'},
                                                          ['Yes'],
                                                          o(close_popup, next)),
                                                   div('clear'),
                                                   br()])])])])])])]));
            $(document.body).append(popup);
            el.attr('href', "#" + id);
            el.magnificPopup(); }

        function remove_person(invite_id, element) {
            project_id = $('#project-id').val();
            $.ajax({type:     'GET',
                    url:      '/projects/' + project_id + '/remove_user/' + invite_id,
                    success:  function(data) {
                        $.magnificPopup.close();
                        element.remove(); }}); }

        function link_person_buttons() {
            $('.people-entry').map(function(i, el) {
                el = $(el);
                var id = el.attr('data-person-id');
                el.find('.delete-person').magnificPopup();
                el.find('.close-delete-person').click($.magnificPopup.close);
                el.find('.confirm-delete-person').click(curry(remove_person, id, el));
            });
        }

        link_person_buttons();

        function run_on_popup() {
            $('#sign-up-form').submit(sign_up);
            $('#log-in-form').submit(log_in);
            $('#password-reset-form').submit(reset_password);
            $('#field-email').val($('#field-email').val()
                                  || $('#field-e-mail').val());
            link_popups(); }

        function link_popups() {
        $('.popup-link').magnificPopup({
            type: 'ajax',
            callbacks: {
            ajaxContentAdded: function() {
                $(this.content).find('.slide-image').find('img').each(function() {
                var $img = $(this);

                $img
                    .height($img.width() * $img.attr('height') / $img.attr('width'))

                    .on('load', function() {
                    $img.css('height', '');
                    });
                });

                this.content.find('.slides').carouFredSel({
                auto: 8000,
                responsive: true,
                width: '100%',
                height: 'variable',
                items: {
                    height: 'variable'
                },
                prev: this.content.find('.slider-prev'),
                next: this.content.find('.slider-next'),
                swipe: true
                });

                        run_on_popup();
            }
            }
        }); }

        link_popups();


        $('#show-password-link').click(function() {
            if ($('#show-password-link').attr('class') == "hide-passwords") {
                $('input#field-password, input#field-new-password, input#field-new-password-confirm')
                    .attr('type', 'password');
                $('#show-password-link').attr('class', '');
                $('#show-password-link').html('Show Passwords'); }
            else{
                $('input#field-password, input#field-new-password, input#field-new-password-confirm')
                    .attr('type', 'text');
                $('#show-password-link').attr('class', 'hide-passwords');
                $('#show-password-link').html('Hide Passwords'); }});

    $('.scroll-to').on('click', function(event) {
        event.preventDefault();

        $('html, body').animate({scrollTop: $($(this).attr('href')).offset().top}, 1000)
    });


        $('form.new-payment-amount').submit(function(event) {
            event.preventDefault();
            var form   = $(this);
            var id     = form.attr('data-id');
            var input  = form.find('input.new-payment-amount-field');
            var span   = $('span.current-payment-amount[data-id="' + id + '"]');
            var price  = parseInt(input.val().match(/[0-9]+/));

            $.ajax({type:    'POST',
                    url:      window.location.pathname + '/update_payment.json',
                    data:    {id: id, amount: price},
                    success:  function(data) {
                        form.css('display', 'none');
                        span.css('display', 'inline');
                        span.find('strong.payment-amount[data-id="' + id + '"]')
                            .html('$' + price.toString());

                        $('.new-payment-amount[data-id="total"] .new-payment-amount-field')
                            .val('$' + data.price.toString());
                        $('strong.payment-amount[data-id="total"], #project-total')
                            .html('$' + data.price.toString());
                        $('a.btn-edit-payment[data-id="total"]')
                            .attr('data-amount', data.price.toString());

                        data.unpaid_payments.map(function(payment) {
                            var id = payment._id.$oid;
                        $('.new-payment-amount[data-id="' + id + '"] .new-payment-amount-field')
                            .val('$' + payment.amount.toString());
                        $('strong.payment-amount[data-id="' + id + '"]')
                            .html('$' + payment.amount.toString());
                        $('a.btn-edit-payment[data-id="' + id + '"]')
                            .attr('data-amount', payment.amount.toString()); }); }}); });

        $('.btn-edit-payment').click(function() {
            var id = $(this).attr('data-id');
            $('span.current-payment-amount[data-id="' + id + '"]')
                .css('display', 'none');
            $('form.new-payment-amount[data-id="' + id + '"]')
                .css('display', 'inline'); });

        $('a.submit-payment').click(function() {
            $(this).parent().submit(); });

        function validate_apply_form(event) {
            var skills           = [$('#skill1'),
                                    $('#skill2'),
                                    $('#skill3')];
            var selected_skills  = [];

            for (var i in skills) {
                if (skills[i].val() && member(selected_skills, skills[i].val())) {
                    event.preventDefault();
                    return notify_duplicate_skill(skills[i]); }
                selected_skills.push(skills[i].val()); }

            return true; }

        function notify_duplicate_skill(skill) {
            $('#error').html("You can't enter the same skill twice!");
            window.location.hash = '#error'; }

        $('#apply-form').submit(validate_apply_form);

    // mobile menu
    $('.expand').on('click', function (event) {
        event.preventDefault();

        $('.header .nav').stop(true, true).slideToggle();
    });

    $('[name="payment-method"]').on('change', function() {
        var $form = $(this).closest('form');
        var oldClass = $form[0].className.match(/payment-method-\w*/);
            $('.cc-req').prop('required', this.value == 'cc');

        $form.removeClass(oldClass && oldClass[0]).addClass('payment-method-' + this.value);
    });


    $('[name="payment-method"]:checked').trigger('change');
    });

    $win.on('scroll', function() {
    if($win.scrollTop() > 99) {
        $('body').addClass('fixed');
    } else {
        $('body').removeClass('fixed');
    };
    });


    function ajaxSubmit($form) {

    var $form = $(this);
    $('.message-status').addClass('hide');

    $form.find('input[type="submit"]').attr('disabled', 'disabled');

    var request = $.ajax({
        url: $form.attr('action'),
        type: $form.attr('method'),
        data: $form.serializeArray(),
        dataType: 'json'
    });

    request.done(function (response) {
        if (response.status === 'success') {
        $form.trigger('reset');

        if (response.page === 'project_form') {
            window.location.href = './project_submitted.html';
        } else {
            alert('Your message has been sent.');
        }

        } else if (response.status === 'email-error') {
        alert(response.message);
        } else {
        alert('Fill all required fields');
        for (i in response.errors) {
            $(':input[name="' + response.errors[i] + '"]').addClass('error');
        };
        }
    });

    request.fail(function(jqXHR, error, status) {
        alert('Something went wrong, please contact the administrator.');
    });

    request.always(function(jqXHR, error, status) {
        $form.find('input[type="submit"]').removeAttr('disabled');
    });
    };

    if (window.location.hash == "#login")
        setTimeout(function() {$('#userlink').click(); }, 1000);

})(jQuery, window, document);




var CartPanel = (function() {

    function CartPanel(element, url) {
    this.element = element;

    this.url = url;

    this.calculator = null;

    this.init();
    };

    CartPanel.prototype.init = function() {
    this.show();

    this.bind();

    this.getContent();
    };

    CartPanel.prototype.bind = function() {
    var that = this;

    $(this.element).find('.side-panel-overlay').on('click', function() {
        that.close();
    });

    $(this.element).on('click.close', '.side-panel-close', function() {
        that.close();
    });

    $(this.element).on('submit', '.side-cart', function(event) {
        event.preventDefault();

        $.ajax({
        url: this.action,
        type: this.method,
        data: $(this).serialize()
        });

        cart.addItems($(this).serializeArray());

        that.close();

        setTimeout(function() {
        cart.showPopout();

        setTimeout(function() {
            $('body').removeClass('items-added');

            cart.toggleCartBar();
        }, 1000);
        }, 600);
    });
    };

    CartPanel.prototype.unbind = function() {
    $(this.element)
        .off('click.close')
        .off('submit')
        .find('.side-panel-overlay').off('click');
    };

    CartPanel.prototype.getContent = function() {
    var that = this;

    $.ajax({
        url     : this.url,
        type    : 'get',
        success : function(data) {
        if($('.product', data).length) {
            that.setContent(data);
        } else {
            that.setError();
            that.removeLoading();
        };
        },
        error   : function() {
        that.setError();
        that.removeLoading();
        }
    })
    };

    CartPanel.prototype.show = function() {
    $(this.element).addClass('visible');
    };

    CartPanel.prototype.hide = function() {
    $(this.element).removeClass('visible');
    };

    CartPanel.prototype.close = function() {

    this.hide();

    this.destroy();
    };

    CartPanel.prototype.setContent = function(data) {

    $(this.element).find('.side-panel-content').html(data);

    $(this.element).find('.counter-input').each(function() {
        counter($(this));
    });

    this.calculator = new Calculator(this.element, {
        itemSelector      : '.calc-item',
        sumHolderSelector : '.calc-value-holder',
        sumTextSelector   : '.calc-value'
    });

    this.removeLoading();
    };

    CartPanel.prototype.removeContent = function(data) {

    this.unbind();

    if(this.calculator) {
        this.calculator.destroy();
    };

    $(this.element).find('.side-panel-content').empty();
    };

    CartPanel.prototype.removeLoading = function() {
    $(this.element).removeClass('loading');
    };

    CartPanel.prototype.setLoading = function() {
    $(this.element).addClass('loading');
    };

    CartPanel.prototype.setError = function() {
    $(this.element).addClass('error');
    };

    CartPanel.prototype.removeError = function() {
    $(this.element).removeClass('error');
    };

    CartPanel.prototype.destroy = function() {
    this.removeError();

    this.setLoading();

    this.removeContent();
    };


    return CartPanel;

})();



var Calculator = (function() {

    function Calculator(element, settings) {
    this.element = element;

    this.settings = settings;

    this.items = this.collectItems();

    this.data = {};

    this.init();
    };

    Calculator.prototype.init = function() {
    this.doCalculation();
    };

    Calculator.prototype.collectItems = function() {
    var itemElements = this.element.querySelectorAll(this.settings.itemSelector);
    var items = [];

    for (var i = 0; i < itemElements.length; i++) {
        var calcItem = {
        element : itemElements[i],
        mathType: itemElements[i].getAttribute('data-math-type') || 'sum',
        value   : itemElements[i].value,
        checked : itemElements[i].checked,
        type    : itemElements[i].type
        };

        this.bindItem(calcItem);

        items.push(calcItem);
    };

    return items;
    };

    Calculator.prototype.bindItem = function(item) {
    var that = this;

    $(item.element).on('change input', function() {
        item.checked = this.checked;
        item.value = this.value;

        that.doCalculation();
    });
    };

    Calculator.prototype.unbindItem = function(item) {
    $(item.element).off('change input');
    };

    Calculator.prototype.doCalculation = function() {
    var sum = 0;
    var multiply = 0;
    var total = 0;
    var count = 0;

    // first sum up all sum items
    for (var i = 0; i < this.items.length; i++) {


        // discard all items that aren't sum
        if(this.items[i].mathType !== 'sum') {
        continue;
        };

        // discard all checkboxes and radios that aren't checked
        if((this.items[i].type === 'checkbox' || this.items[i].type === 'radio') && !this.items[i].checked) {
        continue;
        };

        sum += parseFloat(this.items[i].value);
        count += 1;
    };

    // now sum up all the multipliers
    for (var i = 0; i < this.items.length; i++) {

        // discard all items that aren't sum
        if(this.items[i].mathType !== 'multiply') {
        continue;
        };

        // discard all checkboxes and radios that aren't checked
        if((this.items[i].type === 'checkbox' || this.items[i].type === 'radio') && !this.items[i].checked) {
        continue;
        };

        multiply += parseFloat(this.items[i].value);

        count += parseFloat(this.items[i].value) - 1;
    };


    total = sum * (multiply);

    this.data = {
        total: total,
        count: count
    };

    this.updateView();
    };

    Calculator.prototype.updateView = function() {
    $(this.element).find(this.settings.sumHolderSelector).toggleClass('many', this.data.count > 1 && this.data.total > 0);

    $(this.element).find(this.settings.sumTextSelector).text(this.data.total);
    };

    Calculator.prototype.destroy = function() {
    for (var i = 0; i < this.items.length; i++) {
        this.unbindItem(this.items[i]);
    };
    };


    return Calculator;

})();

var Cart = (function() {

    function Cart() {
    this.items = {};

    this.init();
    };

    Cart.prototype.init = function() {
    this.bind();
    };

    Cart.prototype.bind = function() {
    var that = this;

    $('.cart-continue').on('click', function() {
        $('body').removeClass('items-added');

        that.toggleCartBar();
    });
    };

    Cart.prototype.toggleCartBar = function() {
    $('body').toggleClass('cart-bar-visible', (this.getTotalQty() > 0 && this.getTotalSum() > 0));
    };

    Cart.prototype.addItems = function(items) {
    var product = null;
    var qty = 0;

    for (var i = 0; i < items.length; i++) {
        if(items[i].name === 'product-type') {
        product = items[i].value;

        items.splice(i, 1);
        break;
        };
    };

    for (var i = 0; i < items.length; i++) {
        if(items[i].name.match(/^qty/)) {
        qty += parseFloat(items[i].value);
        };
    };

    for (var i = 0; i < items.length; i++) {
        if(!items[i].name.match(/^qty/)) {
        items[i].qty = qty;

        if(!(product in this.items)) {
            this.items[product] = {};
        };

        this.items[product][items[i].name] = items[i];
        };
    };
    };

    Cart.prototype.getTotalQty = function() {
    var qty = 0;

    for (var productName in this.items) {
        var product = this.items[productName];

        for (var itemName in product) {
        qty += parseFloat(product[itemName].qty);
        };

    };

    return qty;
    };

    Cart.prototype.getTotalSum = function() {
    var total = 0;

    for (var productName in this.items) {
        var product = this.items[productName];

        for (var itemName in product) {
        total += product[itemName].value * product[itemName].qty;
        };

    };

    return total;
    };

    Cart.prototype.getProductsQty = function() {
    var qty = 0;

    for (var productName in this.items) {
        qty += 1;
    };

    return qty;
    };

    Cart.prototype.showPopout = function() {

    $('body').removeClass('cart-bar-visible');

    $('body').addClass('items-added');

    $('body, html').animate({scrollTop: 0});

    $('.cart-qty-bubble').text(this.getProductsQty());
    };


    return Cart;

})();
