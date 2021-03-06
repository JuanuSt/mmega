# megatools multi-account 
Bash script to check multiple registered accounts in mega.nz cloud using [megatools](https://github.com/megous/megatools).

For automated jobs use `mmega_cron.sh`

If you want to save all the information about your files in a database you can check out this others scripts:

* [mmega_pg](https://bitbucket.org/juanust/mmega_pg). Using PostgreSQL as database (preferred).
* [mmega_my](https://bitbucket.org/juanust/mmega_my). Using MySQL as databse (abandoned but still working).

## mmega
Check free space and files of several registered accounts in mega.nz cloud using the nice code megatools written by [megaus](https://github.com/megous).
```
      mmega --config <file> --mode <df|status|up|down|sync> [options]       
      mmega --search <dir> <name> [options]         
```      
> NOTE: The short descriptors -c -m and -s are also accepted.

## Dependencies
- megatools        
- torsocks (if Tor is used)       
- gpg (if encryption is used)        
- curl (if IP is retrieved)         
- dig (if DNS is retrieved)           
- some bash specific commands             

## How it works
This script works in two styles, 'config file' style or 'search' style.

#### Config file style          
It reads a config file with account's parameters (login and directories) for each account (see below). This file is parsed to check common mistakes in format (five fields comma separated). Using this file and the suite megatools the script checks the free space available for each account. If mode `status` is used (see below) it compares files in local and remote directories and summarizes the accounts state. It prints the free space and the number of files to be downloaded or uploaded for each account. If modes `sync|down|up` are used these files are then synchronized accordingly. 

##### The config file         
It contains in each line the account's parameters. The structure is comma separated with 5 fields:

>  name1,username1,passwd1,local_dir1,remote_dir1,        
>  name2,username2,passwd2,local_dir2,remote_dir2,         
>  name3,username3,passwd3,local_dir3,remote_dir3,        
>  ...

Field | Function
----------- | -----------------------------------------------------------------------------------------------
name | The name to describe the account. It will be shortened to ten characters for printing.
username | The registered account mail in mega.nz.
passwd | The registered account password. In plaintext (see below).
local_dir | The account's local directory. It can be left in blank if you only use `df` mode.
remote_dir | The account's remote directory (often /Root). It can be left in blank if you only use `df` mode.

##### Modes for config file style                               
``` 
      mmega --config <file> --mode <df|status|up|down|sync> [options]
```

Mode | Description
------- | ----------------------------------------------------------------------------------------------------------------
`df` | It retrieves Free, Used and Total space in bytes of each account. The bytes are transformed to human readable format for printing (so these numbers are approximations). It shows this information per account and summarizes the total. This mode make only one connection per account using megadf command.
`status` | It compares files in local and remote directories using megacopy command (three times, slow). It runs in --dryrun mode and creates temporal files with the list of files of each account. It prints the free space and the number of files to be downloaded or uploaded for each account. It also shows the total files in cloud (only cloud files are shown). The process for large lists can be very slow. 
`up` | It uses status mode and after upload all files for all unsynchronized accounts.
`down` | It uses status mode and after download all files for all unsynchronized accounts.
`sync` | It uses status mode and after upload and download all files for all unsynchronized accounts. It is not a proper synchronization process as no files are deleted (in order not to delete different versions).

> NOTE: `status` mode doesn't show the files, only the number of files. If you want to check what files have been downloaded or uploaded you should use `--files` option (see below).

> NOTE: When using `up|down|sync` modes mega.nz site and megatools provide a security method to never overwrite the files. If there are discrepancies, the files are marked with a number (that indicates the node) and the word conflict. You will have to check 'by hand' these discrepancies (See megaus code at github). However if two copies of the same file are named the different way they will be considered as two different files.

#### Search style
```
      mmega --search <dir> <name> [options]
```
Megatools allows a file with account login parameters to avoid writing them each time (see megatools manual). If you have several of them, you can you use this style to find them and consult the accounts (and the path to these config files). It only retrieves Free, Used and Total space in cloud. It prints Free, Total, username and path to config file for each account. Finally it summarizes this information.

The search dir is mandatory. The name can be left in blank (preferred method) or you can pass it as argument. When asked for the name you should use wildcards to search for a pattern in your accounts (as .megarc*) but if you pass it as argument do not use wildcards, the script will add * to this name to search for a pattern and not a specific name.

Search mode only accept the options `--tor on|off` (see below)

#### Options
Option | Description
--------- | --------------------------------------------------------------------------------------------------------------
`--tor` | It only accepts the arguments on and off. By default is not set because it implies a connection to api.ipify.org to extract the IP. You can change that (line 467). If set to 'off' the script will show the IP and DNS used in the connection. If set to 'on' the connection will be proxied trough Tor using torsocks. Tor and torsocks have to be installed and working.
`--passwd` | It is the password of gpg private key (see Notes). It can be left in blank and you will be asked for it (preferred method) or you can pass the password as argument. If password contains spaces you have to write it between double quotation marks ("P@SS W0RD").
`--files` | It shows the files to be uploaded and downloaded. By default status mode don't show file names, so this option can be useful to check the files to be synchronized before to do it.

> NOTE: The short descriptors -t -f and -p are also accepted.

#### Notes
The whole config file can be encrypted if the private key is in the system's gpg keyring. If private key is password-protected you will be asked for it. For a cron job you can use a password-less key or pass the password as argument.

The script uses a color code to summarizes the state of accounts (see screenshots). Thus synchronized accounts are shown in green, unsynchronized in yellow and fail in red. The fail state means there were errors with directories (local or remote). The errors parsing the config file are shown in black. For cron mail reporting this color code can be annoying. If you want you can set colors variables to nothing in the beginning of script or you can use the new mmega_cron.sh script which has been adapted for a cron job.

IMP: Check that MEGACOPY and MEGADF variables (lines 94 adn 95) point to your binaries (usually in /usr/bin/ or /usr/local/bin). If they are set wrong all accounts give error.

The code is far from being optimized, is a simple script that I use as cron job to maintain a regular contact with my accounts after the change of policy mega.nz where unused accounts are eliminated.

### Examples
Check status for accounts in config file accounts_mega.gpg and show the files:
```
      mmega --config accounts_mega.gpg --mode status --files                     (gpg will ask)
      mmega --config accounts_mega.gpg --mode status --files --passwd            (script will ask)
      mmega --config accounts_mega.gpg --mode status --files --passwd "PASSWORD"
```
![Alt text](/images/status_gpg_1.png?raw=true)

Synchronize all unsyncronized accounts in the config file accounts_mega.gpg using Tor:
```
      mmega -c accounts_mega.gpg -m sync --tor on --passwd
```
![Alt text](/images/sync_tor3.jpg?raw=true)

Check all space available for all accounts in accountsmega config file:
```
      mmega -c /home/user/accountsmega -m df
```
![Alt text](/images/mode_df_1.png?raw=true)

Search for megarc* files in /home/user/ directory and show accounts and connection data:
```
      mmega --search /home/user/ megarc -t off
```
![Alt text](/images/search_mode1.png?raw=true)

Cron job format

![Alt text](/images/cronjobformat2.png?raw=true)


