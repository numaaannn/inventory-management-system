<?php
	$pdoOptions = [
		PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
	];
	if (defined('PDO::MYSQL_ATTR_CONNECT_TIMEOUT')) {
		$pdoOptions[PDO::MYSQL_ATTR_CONNECT_TIMEOUT] = 5;
	}

	try {
		$conn = new PDO(DSN, DB_USER, DB_PASSWORD, $pdoOptions);
	} catch (PDOException $e) {
		echo $e->getMessage();
		exit();
	}
?>
