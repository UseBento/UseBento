<?php 
	require dirname(__FILE__) . '/functions.php';

	if ($_SERVER['REQUEST_METHOD'] === 'POST') {
		$errors = array();
		$response = array(
			'status' => 'error',
			'message' => 'Please fill all required fields.',
		);

		if (isset($_POST['contact-form'])) {
			$required = array('field-name', 'field-subject', 'field-message');

		} elseif (isset($_POST['application-form'])) {
			$required = array('field-full-name', 'field-e-mail');

		} elseif (isset($_POST['project-form'])) {
			$required = array('field-name', 'field-project-type', 'field-e-mail', 'field-type-work', 'field-description', 'field-inspire', 'field-how');
			$response['page'] = 'project_form';
			
		} elseif ( isset($_POST['contact-form-agency']) ) {
			$required = array('field-name', 'field-e-mail', 'field-agency', 'field-message');
		}

		$select_fields = array('field-project-type', 'field-type-work', 'field-how');
		
		
		foreach ($required as $field) {
			if ($field  === 'field-e-mail' && !filter_var($_POST[$field], FILTER_VALIDATE_EMAIL)) {
				$errors[] =  $field;
			} elseif (in_array($field, $select_fields) && $_POST[$field] === '0') {
				$errors[] =  $field;
			} elseif ( empty($_POST[$field] ) ) {
				$errors[] =  $field;
			}
		}

		if ( !$errors ) {
			$mail_sent = mailer();

			if ($mail_sent) {
				$response['status'] = 'success';
				$response['message'] = 'Message has been sent';
			} else {
				$response['status'] = 'email-error';
				$response['message'] = 'Something went wrong. Please try again later.';
			}

		} else {
			$response['errors'] = $errors;
		}

		if(is_ajax()) {
			echo json_encode($response);	
			exit;
		} else {
			?>
			<html>
				<body>
					<h3><?php echo $response['message']  ?></h3>
				</body>
			</html>
			<?php
		}
	}

?>
