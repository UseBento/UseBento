<?php

//Contact Form
$contact_form_receiver = 'nnaimov.2create@gmail.com';
$contact_form_subject = 'Contact Form';


//Application Form
$application_form_receiver = 'nnaimov.2create@gmail.com';
$application_form_subject = 'Application Form';

//Project Form 
$project_form_receiver = 'nnaimov.2create@gmail.com';
$project_form_subject = 'Subject Form';

if (isset($_POST['contact-form'])) {
	$reveiver = $contact_form_receiver;
	$subject = $contact_form_subject;
	$email = $field_name;
} elseif (isset($_POST['application-form'])) {
	$reveiver = $application_form_receiver;
	$subject =  $application_form_subject;
	$email = $field_email;
} elseif (isset($_POST['project-form'])) {
	$reveiver = $project_form_receiver;
	$subject =  $project_form_subject;
	$email = $field_email;
};

$mail_status = "";
$mail = new PHPMailer(); // create a new object
$mail->IsSMTP(); // enable SMTP
$mail->SMTPAuth = true; // authentication enabled
$mail->SMTPSecure = 'ssl'; // secure transfer enabled REQUIRED for GMail
$mail->Host = "smtp.gmail.com";
$mail->Port = 465; // or 587
$mail->IsHTML(true);
$mail->Username = "nnaimov.2create@gmail.com"; //email
$mail->Password = "UGEJfg5029";//email password
$mail->From = $email;
$mail->FromName = $field_name;
$mail->Subject = $subject;
$mail->AddAddress('nnaimov.2create@gmail.com');
