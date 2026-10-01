<?php
header('Content-Type: application/json');

$health = ['status' => 'ok', 'service' => 'inventory-management-system'];

try {
	require_once __DIR__ . '/inc/config/constants.php';
	$conn = new PDO(DSN, DB_USER, DB_PASSWORD);
	$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
	$health['database'] = 'connected';
} catch (Throwable $e) {
	http_response_code(503);
	$health['status'] = 'degraded';
	$health['database'] = 'unavailable';
}

echo json_encode($health);
