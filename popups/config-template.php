<?php

//Contact Form
$contact_form_receiver = ' info@teamlead.io';
$contact_form_subject = 'Contact Form';


//Application Form
$application_form_receiver = 'info@teamlead.io';
$application_form_subject = 'Application Form';

//Project Form 
$project_form_receiver = ' project@teamlead.io';
$project_form_subject = 'Project Form';

if (isset($_POST['contact-form'])) {
	$reveiver = $contact_form_receiver;
	$subject = $contact_form_subject;
	$email = '';
} elseif (isset($_POST['application-form'])) {
	$reveiver = $application_form_receiver;
	$subject =  $application_form_subject;
	$email = $field_email;
} elseif (isset($_POST['project-form'])) {
	$reveiver = $project_form_receiver;
	$subject =  $project_form_subject;
	$email = $field_email;
};

$mail = new PHPMailer(); // create a new object
$mail->IsHTML(true);
$mail->From = $email;
$mail->FromName = $field_name;
$mail->Subject = $subject;
$mail->AddAddress($receiver);
