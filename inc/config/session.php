<?php
	if (session_status() === PHP_SESSION_NONE) {
		$sessionPath = getenv('SESSION_SAVE_PATH') ?: sys_get_temp_dir();
		if (is_dir($sessionPath) && is_writable($sessionPath)) {
			session_save_path($sessionPath);
		}
		session_start();
	}
?>
