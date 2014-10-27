<?php

//Contact Form
$contact_form_receiver = 'jculbertson@gmail.com';
$contact_form_subject = 'Contact Form';


//Application Form
$application_form_receiver = 'jculbertson@gmail.com';
$application_form_subject = 'Application Form';

//Project Form 
$project_form_receiver = 'jculbertson@gmail.com';
$project_form_subject = 'Project Form';

if (isset($_POST['contact-form'])) {
	$receiver = $contact_form_receiver;
	$subject = $contact_form_subject;
	$email = '';
} elseif (isset($_POST['application-form'])) {
	$receiver = $application_form_receiver;
	$subject =  $application_form_subject;
	$email = $field_email;
} elseif (isset($_POST['project-form'])) {
	$receiver = $project_form_receiver;
	$subject =  $project_form_subject;
	$email = $field_email;
};

if (empty($email)) {
	$email = 'no-reply@example.com';
};

$mail = new PHPMailer(); // create a new object
$mail->IsHTML(true);


$mail->From = $email;
$mail->FromName = $field_name;
$mail->Subject = $subject;
$mail->AddAddress($receiver);