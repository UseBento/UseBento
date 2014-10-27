;(function($, window, document, undefined) {
	var $win = $(window);
	var $doc = $(document);

	$doc.ready(function() {
		var Wheight = $win.height()

		// mobile menu
		$('.expand').on('click', function () {

			$('.header .nav').stop(true, true).slideToggle();
			return false;
		});


		// HIDE / SHOW HEADER
		$win.scroll(function () {
			var $target = $('.top');
			var target_offset  = $target.offset().top

			if (target_offset > 100) {
				$('body').addClass('fixed');
			} else if (target_offset < 100 ) {
				$('body').removeClass('fixed');
			}
		})		

		//Fullscreener
		$('.intro-bg').fullscreener();

		$(".select").selectbox();

		$(".group1").colorbox({
			opacity: 0.8,
			rel:'group1',
			current: false,
			close: false
		});

		console.log('OK');
		$('form').on('submit', function() {
			var $form = $(this);
			$('.message-status').addClass('hide');
			
			$form.find('input[type="submit"]').attr('disabled', 'disabled');
			$form.find(':input').removeClass('error');

			var request = $.ajax({
				url: $form.attr('action'),
				type: $form.attr('method'),
				data: $form.serializeArray(),
				dataType: 'json',
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
			return false;
		});
	});
})(jQuery, window, document);
