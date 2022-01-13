# remote_syslog
## _OpenRC startup script for multilog_
## Installation
Download latest stable version  **remote_syslog**
[Latest stable version remote_syslog](https://github.com/papertrail/remote_syslog2/releases)
Install package:
```sh
dpkg -i remote*.deb
```
## Confguration
Open `nano /etc/init.d/remote_syslog` and insert new code from `remote_syslog.sh`

Open `nano /etc/log_files.yml` change **port** and add you log files:
```sh
destination:
  host: logs6.papertrailapp.com
  port: 37740
  protocol: tls
hosts:
  myappexample: /home/user/Dev/hub/quests/worldofescapes/myappexample/log/development.log
  worldofescapes: /home/user/Dev/hub/quests/worldofescapes/worldofescapes.com/log/development.log
 ```
 ## Run & Autostart
 ```sh
 # run remote_syslog
 /etc/init.d/remote_syslog start
 # autostart remote_syslog
 update-rc.d remote_syslog defaults
 ```
 See status:
 ```sh
 /etc/init.d/remote_syslog status
 # or
service remote_syslog status
 ```
 **That's all!**
