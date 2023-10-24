# Set dynamic MOTD and ISSUE

Generate System info and make visibile from tty and shell login



Clone repository to local tmp path:

```bash
cd /tmp/
git clone https://github.com/AlessandroPerazzetta/dynamic-motd-issue.git
```

Run the setup script:

```bash
$ ./setup.sh
```

This script copy files from [update-motd.d](https://github.com/AlessandroPerazzetta/dynamic-motd-issue/tree/main/update-motd.d "update-motd.d") to /etc/update-motd.d/



- ### [00-header](https://github.com/AlessandroPerazzetta/dynamic-motd-issue/blob/main/update-motd.d/00-header)
  
  This file generate header info, get pretty name from lsb release, hostname and kernel

- ### [10-sysinfo](https://github.com/AlessandroPerazzetta/dynamic-motd-issue/blob/main/update-motd.d/10-sysinfo)
  
  This file generate system info, like date, current system load, memory usage, users, time, processes and ip address

- ### [90-footer](https://github.com/AlessandroPerazzetta/dynamic-motd-issue/blob/main/update-motd.d/90-footer)
  
  This file generate footer info, get details from motd



    This script also generate new issue after interface is up, create update-issue file in /etc/network/if-up.d/update-issue and get info from previous 00-header and 10-sysinfo
