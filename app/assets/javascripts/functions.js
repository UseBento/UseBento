function get_tco_token() {
    var payload = {sellerId:        $('#seller_id').val(),
                   publishableKey:  $('#publishable_key').val(),
                   ccNo:            $('#credit-card-number').val(),
                   expMonth:        $('#expr-date-month').val(),
                   expYear:         $('#expr-date-year').val(),
                   cvv:             $('#cvv').val()};

    TCO.loadPubKey('sandbox', function() {
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

                                var userlink = $('#userlink');
                                userlink.attr('href', '/profile');
                                userlink.attr('data-userid', data.id);
                                userlink.html(data.username);
                                $.magnificPopup.close(); 

                                var projects_link = $('a[href="/services/select"]');
                                projects_link.html('PROJECTS');
                                projects_link.attr('href', '/projects/list');

                                var full_name = $('#field-full-name');
                                full_name.val(data.username);
                                full_name.attr('type', 'hidden');
                                full_name.parent().append(data.username);

                                var email = $('#field-e-mail');
                                email.val(data.email);
                                email.attr('type', 'hidden');
                                email.parent().append(data.email);

                                var company = $('#field-name-business');
                                if (!company.val()) 
                                    company.val(data.company);

                                var target = $('#field-target');
                                if (!target.val()) 
                                    target.val(data.audience);

                                var keywords = $('#field-keywords');
                                if (!keywords.val()) 
                                    keywords.val(data.keywords); }}}}); }

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

        function submit_project_message(event) {
            event.preventDefault();
            var message       = $('#message-box').val();
            var project_id    = $('#project-id').val();
            
            function success(data) {
                var message_li = 
                        build_el(
                            li('',
                               [div('avtar',
                                    [img({src: data.avatar,
                                          alt: ''})]),
                                div('dtl_box',
                                    [h4('', [data.user_name]),
                                     span('message-body',
                                          [unescape(data.body)]),
                                     p('info_text',
                                       ['Posted ' + data.posted])])])); 

                message_li.insertBefore($('li#message-form-li')); 
                message_li.children('.dtl_box')
                    .children('.message-body')
                    .html(unescape(data.body)); 
                $('#message-box').val($('#message-box')[0].defaultValue); 
                reset_message_form(); }

            var data = {message_body: message};
            data     = new FormData($('#message-form')[0]);

            $.ajax({type: 'POST',
                    url:  '/projects/' + project_id + '/message.json',
                    data: data,
                    enctype: 'multipart/form-data',
                    processData: false,
                    contentType: false,
                    success: success}); }

        function reset_message_form() {
            $('input[name^="file-upload-"]').map(function(i,input) {
                $(input).remove(); }); };

        $('#message-form').submit(submit_project_message);
        $('#message-form').bind('reset', reset_message_form);
        $('#message-box').change(function() {
            $('.cancel_btn').css('display', 'inline'); });                

        var file_upload_id = 1;
        $('#file-link').click(function(event) {
            event.preventDefault();
            var file_upload = $('#file-upload');
            file_upload.change(function() {
                file_upload.css('display', 'block');
                file_upload.attr('id', 'file-upload-' + file_upload_id.toString());
                file_upload.attr('name', 'file-upload-' + file_upload_id.toString());
                file_upload.parent().append(
                    build_el(input({id:    'file-upload', 
                                    type:  'file', 
                                    style: 'display:none'})));
                file_upload_id++; });
            file_upload.trigger('click'); });

        function check_first() {
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
            var page_count     = page_counter ? page_counter.val() : 1;
            var responsive     = $('#field-desktop-mobile').prop('checked');
            
            if ($('input[name="service_name"]').val() == 'social_media_design') 
                page_count = $('input.header-type')
                    .map(function(i, ii) { 
                        return $(ii).prop('checked'); })
                    .filter(function(i, x) { 
                        return x; }).length; 

            if (price === 0) return;
            if (responsive) 
                price += 20;

            price = price * page_count;
            button.val('GET STARTED - $' + price); }

        $('#pages-count').change(update_price);
        $('.header-type').change(update_price);
        $('#field-desktop-mobile, #field-desktop-only').change(update_price);

        function run_on_popup() {
            $('#sign-up-form').submit(sign_up); 
            $('#log-in-form').submit(log_in);
            $('#password-reset-form').submit(reset_password);
            $('#field-email').val($('#field-e-mail').val());
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
