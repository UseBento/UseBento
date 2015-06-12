jQuery(document).ready(function($) {
  $('.ui.checkbox')
    .checkbox()
  ;

  $('.available-button-area').each(function() {
    console.log('toggle button event');
    if ($(this).find('.ui.toggle.checkbox').hasClass('checked')) {
      $(this).parent().find('label').val('AVAILABLE');
    } else {
      $(this).parent().find('label').val('UNAVAILABLE');
    }
  });

  $('.ui.toggle.checkbox').on('click', function() {
    console.log('toggle button event');
    if ($(this).hasClass('checked')) {
      $(this).parent().find('> label').text('AVAILABLE');
    } else {
      $(this).parent().find('> label').text('UNAVAILABLE');
    }
  });
});
