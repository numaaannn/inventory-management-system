<?php
	require_once('../../inc/config/session.php');
	
	unset($_SESSION['loggedIn']);
	unset($_SESSION['fullName']);
	session_destroy();
	header('Location: ../../login.php');
	exit();
?>