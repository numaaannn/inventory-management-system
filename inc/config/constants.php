<?php
	// Root url for the site. Follows whichever address the browser used,
	// so the same files work on localhost and on a public link.
	$documentRoot = isset($_SERVER['DOCUMENT_ROOT']) ? realpath($_SERVER['DOCUMENT_ROOT']) : false;
	$appRoot = realpath(__DIR__ . '/../..');
	$basePath = '/';
	if ($documentRoot && $appRoot) {
		$documentRoot = str_replace('\\', '/', $documentRoot);
		$appRoot = str_replace('\\', '/', $appRoot);
		if (stripos($appRoot, $documentRoot) === 0) {
			$relative = trim(substr($appRoot, strlen($documentRoot)), '/');
			$basePath = ($relative === '') ? '/' : '/' . $relative . '/';
		}
	}
	$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
		|| (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https');
	$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
	define('ROOT_URL', ($isHttps ? 'https' : 'http') . '://' . $host . $basePath);
	
	
	// Database parameters (override on the server via inc/config/constants.local.php)
	$dbConfig = [
		'DB_HOST' => 'localhost',
		'DB_NAME' => 'shop_inventory',
		'DB_USER' => 'root',
		'DB_PASSWORD' => '',
	];
	$localConfigPath = __DIR__ . '/constants.local.php';
	if (is_readable($localConfigPath)) {
		$localConfig = include $localConfigPath;
		if (is_array($localConfig)) {
			$dbConfig = array_merge($dbConfig, $localConfig);
		}
	}
	define('DB_HOST', $dbConfig['DB_HOST']);
	define('DB_NAME', $dbConfig['DB_NAME']);
	define('DB_USER', $dbConfig['DB_USER']);
	define('DB_PASSWORD', $dbConfig['DB_PASSWORD']);
	define('DSN', 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME);
?>