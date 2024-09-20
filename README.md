# Cloudflare Dynamic DNS
This script is used to update DNS record for Cloudflare.
# Getting Started
1. Clone this repo to home directory
```shel
git clone https://github.com/dongcodebmt/cloudflare-ddns.git
```
2. Edit `config.conf` and replace the values with your own.
```shell
cloudflare_api_token=api_token              # Generate your token with Zone.DNS permission at: https://dash.cloudflare.com/profile/api-tokens
cloudflare_record_name=home.example.com     # The record you want to update
cloudflare_a_record=true                    # Set to false to disable update DNS record for IPv4
cloudflare_aaaa_record=false                # Set to false to disable update DNS record for IPv6
event_log=true                              # Set to false to disable log
```
3. Edit crontab
```shell
sudo crontab -e
```
4. Add the following lines to the crontab
```shell
# Run script every 5 minutes
*/5 * * * * /home/username/cloudflare-ddns/sync.sh
```
