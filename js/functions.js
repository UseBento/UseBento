;(function($, window, document, undefined) {
	var $win = $(window);
	var $doc = $(document);

	$doc.ready(function() {

		window.cart = new Cart();


		$('.product-tile, .product-link').on('click', function(event) {
			event.preventDefault();

			new CartPanel(document.querySelector('.side-panel-holder'), this.href);
		});


		$('form:not(.form-required)').on('submit', function(event) {
			event.preventDefault();

			ajaxSubmit($(this));
		});


		$('.form-required').each(function() {
			var $form = $(this);
			new Validator(this, {
				classHolder : '.field',
				validClass  : 'valid',
				errorClass  : 'error',
				onSubmit    : function(event) {
					event.preventDefault();

					ajaxSubmit($form);
				}
			});
		});



		// UI Helpers
		$('.intro-bg').fullscreener();

		$('.select').selectbox();

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
				}
			}
		});


		$('.scroll-to').on('click', function(event) {
			event.preventDefault();

			$('html, body').animate({scrollTop: $($(this).attr('href')).offset().top}, 1000)
		});



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

})(jQuery, window, document);



function counter($element) {
	var $field = $element.find('.counter-field');
	var value = parseInt($field.val());
	var setValue = function(newVal) {
		value = Math.max(0, newVal);

		$field.val(value).trigger('change');
	};

	$element
		.off('click.counter')
		.on('click.counter', '.counter-control-minus', function() {
			setValue(value - 1)
		})
		.on('click.counter', '.counter-control-plus', function() {
			setValue(value + 1);
		});

};


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
