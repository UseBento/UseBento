jQuery(document).ready(function($) {
  var jFieldSkill;
  var field_value;

  // var jFieldSkill = $('#field-skill_1');
  // var field_value = jFieldSkill.attr('value');
  // console.log(field_value);

  // if (field_value != undefined && field_value != "") {
  //   jFieldSkill.find('option').each(function() {
  //     if ($(this).val() == field_value) {
  //       $(this).attr('selected', 'selected');
  //       return;
  //     }
  //   });  
  // }

  // jFieldSkill = $('#field-skill_2');
  // field_value = jFieldSkill.attr('value');

  // if (field_value != undefined && field_value != "") {
  //   jFieldSkill.find('option').each(function() {
  //     if ($(this).val() == field_value) {
  //       $(this).attr('selected', 'selected');
  //       return;
  //     }
  //   });  
  // }

  for (var i=1; i<4; i++) {
    jFieldSkill = $('#field-skill_' + i.toString());
    field_value = jFieldSkill.attr('value');
    if (field_value != undefined && field_value != "") {
      jFieldSkill.find('option').each(function() {
        if ($(this).val() == field_value) {
          $(this).attr('selected', 'selected');
          return;
        }
      });  
    }
  }
  
});