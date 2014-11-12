;(function($, window, document, undefined) {
	var $win = $(window);
	var $doc = $(document);

	$doc.ready(function() {

		new Calculator($('.side-panel')[0], {
			itemSelector: '.calc-item',
			sumHolderSelector: '.calc-value-holder',
			sumTextSelector: '.calc-value'
		});

		$('.counter-input').each(function() {
			counter($(this));
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


		$('form').on('submit', function(event) {
			event.preventDefault();

			var $form = $(this);
			$('.message-status').addClass('hide');
			
			$form.find('input[type="submit"]').attr('disabled', 'disabled');
			$form.find(':input').removeClass('error');

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
		});
	});

	$win.on('scroll', function() {
		if($win.scrollTop() > 99) {
			$('body').addClass('fixed');
		} else {
			$('body').removeClass('fixed');
		};
	});

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

	}
		
})(jQuery, window, document);


var Calculator = (function() {

	function Calculator(element, settings) {
		this.element = element;

		this.settings = settings;

		this.items = this.collectItems();

		this.data = {};

		this.init();
	};

	Calculator.prototype.init = function() {
		
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
		console.log(this.data.count);
		$(this.element).find(this.settings.sumHolderSelector).toggleClass('many', this.data.count > 1 && this.data.total > 0);

		$(this.element).find(this.settings.sumTextSelector).text(this.data.total);
	};


	return Calculator;

})();