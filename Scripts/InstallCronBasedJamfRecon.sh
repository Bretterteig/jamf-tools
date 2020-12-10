#!/bin/zsh
if ! grep -q '/usr/local/jamf/bin/jamf recon' '/usr/lib/cron/tabs/root';then
	{ crontab -l -u root 2>/dev/null; echo '* 10 * * * /usr/local/jamf/bin/jamf recon'; } | crontab -u root -
fi