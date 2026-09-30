# Copy to host-credentials.ps1 and fill in after you buy hosting.
# Do not commit host-credentials.ps1 (it is gitignored).

$Deploy = @{
	FtpHost     = 'ftp.yourdomain.com'
	FtpUser     = 'your_ftp_username'
	FtpPassword = 'your_ftp_password'
	RemoteRoot  = '/public_html'   # or /domains/yourdomain.com/public_html

	DbHost      = 'localhost'
	DbName      = 'youruser_shop'
	DbUser      = 'youruser_shopuser'
	DbPassword  = 'your_db_password'

	SiteUrl     = 'https://yourdomain.com'
}
