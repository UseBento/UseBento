<?php
	function is_ajax() {
		return (bool) isset($_SERVER['HTTP_X_REQUESTED_WITH']) && !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest';
	}

	function mailer() {

		require_once dirname(__FILE__) . '/PHPMailer-master/PHPMailerAutoload.php';
		require dirname(__FILE__) . '/../config-template.php';
		
		if (isset($_POST['contact-form'])) {
			$field_name = $_POST['field-name'];
			$field_subject = $_POST['field-subject'];
			$field_message = $_POST['field-message'];
			$field_email = $_POST['field-e-mail'];

			$template = 'mail-template-contacts.php';
			$receiver = $contact_form_receiver;
			$subject = $contact_form_subject;
			$email = $field_email;

		} elseif (isset($_POST['application-form'])) {
			$field_name = $_POST['field-full-name'];
			$field_email = $_POST['field-e-mail'];
			$field_portfolio = $_POST['field-portfolio-url'];
			$field_dribble = $_POST['field-dribbble-url'];
			$field_behance = $_POST['field-behance-url'];
			$template = 'mail-template-application.php';

			$receiver = $application_form_receiver;
			$subject =  $application_form_subject;
			$email = $field_email;

		} elseif (isset($_POST['project-form'])) {
			$field_name = $_POST['field-name'];
			$field_company_name = $_POST['field-company-name'];
			$field_project_type = $_POST['field-project-type'];
			$field_email = $_POST['field-e-mail'];
			$field_website = $_POST['field-website'];
			$field_type_work = $_POST['field-type-work'];
			$field_description = $_POST['field-description'];
			$field_inspire = $_POST['field-inspire'];
			$field_how = $_POST['field-how'];
			$template = 'mail-template-project.php';

			$receiver = $project_form_receiver;
			$subject =  $project_form_subject;
			$email = $field_email;
			
		} elseif ( isset($_POST['contact-form-agency']) ) {
			$field_name = $_POST['field-name'];
			$field_email = $_POST['field-e-mail'];
			$field_agency = $_POST['field-agency'];
			$field_message = $_POST['field-message'];
			$template = 'mail-template-contacts-agency.php';

			$receiver = $contact_agency_receiver;
			$subject =  $contact_agency_subject;
			$email = $field_email;
		};

		if ( empty($email) ) {
			$email = 'no-reply@example.com';
		};
		

		$mail = new PHPMailer(); // create a new object
		$mail->IsHTML(true);
		$mail->From = $email;
		$mail->FromName = $field_name;
		$mail->Subject = $subject;
		$mail->AddAddress($receiver);

		ob_start();
		require $template; // add $template after creating mail-template for each form;
		$content = ob_get_contents();
		ob_end_clean();
		$mail->Body = $content;
		

		if($mail->Send()) {
 		   return true;
		}
		return false;
	}

