;(function($, window, document, undefined) {
	var $win = $(window);
	var $doc = $(document);

	$doc.ready(function() {


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
		
})(jQuery, window, document);
