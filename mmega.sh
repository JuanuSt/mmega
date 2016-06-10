#!/bin/bash

# ------------------------------------------------------------------
# [Kass] Check all registered accounts
#
#
# ------------------------------------------------------------------

VERSION=0.9
SUBJECT=mmega
USAGE="mmega -c <file> -m <mode> [options]\n       mmega -s <dir> <name> [options]"

# -- Text color variables ----------------------------------------

txtblk=$(tput setaf 0)  # black
txtred=$(tput setaf 1)  # red
txtgrn=$(tput setaf 2)  # green
txtylw=$(tput setaf 3)  # yellow
txtblu=$(tput setaf 4)  # blue
txtpur=$(tput setaf 5)  # magenta
txtcyn=$(tput setaf 6)  # cyan
txtwht=$(tput setaf 7)  # white

txtdef=$(tput setaf 9)  # text default
txtrst=$(tput sgr0)     # text reset
txtund=$(tput smul)     # text underlined
txtbld=$(tput bold)     # text bold

# -- Symbols ------------------------------------------------------
up_arrow=$'\xe2\x96\xb2'
down_arrow=$'\xe2\x96\xbc'
right_arrow=$'\xe2\x96\xb6'
left_arrow=$'\xe2\x97\x80'

hlarrows=$'\xe2\x87\x86'
hrarrows=$'\xe2\x87\x84'

varrows_down=$'\xe2\x87\xb5'
varrows_up=$'\xe2\x87\x85'

circle=$'\xe2\x97\x8f'
kass=$'\xe2\x93\x9a'
good=$'\xe2\x9c\x93'
watch=$'\xe2\x8c\x9a'
point=$'\xe2\x80\xa2'

# -- Symbols with colors ------------------------------------------
up_arrow_red="${txtred}${up_arrow}${txtrst}"
down_arrow_grn="${txtgrn}${down_arrow}${txtrst}"

down_arrow_blu="${txtblu}${down_arrow}${txtrst}"
up_arrow_blu="${txtblu}${up_arrow}${txtrst}"

varrows_down_blk="${txtblk}${varrows_down}${txtrst}"
point_blk="${txtblk}${point}${txtrst}"

varrows_down_bold="${txtbld}${varrows_down}${txtrst}"
hrarrows_blu_bold="${txtbld}${txtblu}${hrarrows}${txtrst}"

circle_grn="${txtgrn}${circle}${txtrst}"
circle_red="${txtred}${circle}${txtrst}"
circle_ylw="${txtylw}${circle}${txtrst}"
circle_blk="${txtblk}${circle}${txtrst}"

good_grn="${txtgrn}$good${txtrst}"

plus="[${txtgrn}+${txtrst}]"
minus="[${txtred}-${txtrst}]"
excl="[${txtylw}!${txtrst}]"

# -- Creating secure temporal directory -----------------------------
TMP_DIR_p=${TMPDIR-/tmp}
TMP_DIR=$TMP_DIR_p/$SUBJECT.$RANDOM.$RANDOM.$RANDOM.$$
    (umask 077 && mkdir $TMP_DIR) || {
     echo -e "${minus} Could not create temporary directory" 1>&2;
     echo;
     exit 1
     }

# -- Creating lock file ---------------------------------------------
LOCK_FILE=/tmp/$SUBJECT.lock
if [ -f "$LOCK_FILE" ]; then
   echo;
   echo -e "${minus} Script is already running";
   echo;
   exit 1;
fi
touch $LOCK_FILE

# -- Deleting tmp directory and lock file at exit -------------------
trap "rm -rf $TMP_DIR $LOCK_FILE" EXIT

# -- Variables ------------------------------------------------------------------------------------------------------------------
HOST=$(hostname)
date=$(date +"%d.%m.%y")
hour=$(date +"%H:%M")

CONF_FILE=
CONF_FILES=
CHECK_MODE=

SEARCH_MODE="off"
SEARCH_DIR="/home/"
SEARCH_NAME=".megarc*"

GPG_KEY=
GPG_PW=

TOR_MODE=

accounts_err=0

# -- Title -----------------------------------------------------------------------------------------------------------------------
clear
echo
echo -e "${txtund}  ${txtrst} ${txtred}MEGA${txtrst}tools multi-account ${kass} ${txtund}                                     v.$VERSION${txtrst}"
echo -e "                                                       ${txtgrn}$hour${txtrst} $watch ${txtblu}$date${txtrst}"


# -- checking arguments passed to the script --------------------------------------------------------------------------------------

# States
#pass
if [[ "$@" == *"-p"* ]] || [[ "$@" == *"--passwd"* ]];then
   pass_op="on"
else
   pass_op="off"
fi
#conf file
if [[ "$@" == *"-c"* ]] || [[ "$@" == *"--config"* ]];then
   conf_op="on"
else
   conf_op="off"
fi

#Search mode
if [[ "$@" == *"-s"* ]] || [[ "$@" == *"--search"* ]];then
   search_op="on"
else
   search_op="off"
fi

#show files
if [[ "$@" == *"-f"* ]] || [[ "$@" == *"--files"* ]];then 
   fil_op="on"
else
   fil_op="off"
fi
#tor
if [[ "$@" == *"-t"* ]] || [[ "$@" == *"--tor"* ]];then
   tor_op="on"
else
   tor_op="off"
fi

# No argument given
if [[ $# == 0 ]]; then
   echo
   echo -e "${minus} You have to choose between search or config styles"
   echo
   echo -e " USAGE $USAGE"
   echo
   exit 1
fi

# only pass
if [[ $# == 1 ]] && [[ "$pass_op" == "on" ]]; then
   echo
   echo -e "${minus} You can't use passwd alone"
   echo
   echo -e " USAGE $USAGE"
   echo
   exit 1
fi

#only files
if [[ $# == 1 ]] && [[ "$files_op" == "on" ]]; then
   echo
   echo -e "${minus} You can't use files alone"
   echo
   echo -e " USAGE $USAGE"
   echo
   exit 1
fi

#only tor
if [[ $# == 1 ]] && [[ "$tor_op" == "on" ]]; then
   echo
   echo -e "${minus} You can't use Tor alone"
   echo
   echo -e " USAGE $USAGE"
   echo
   exit 1
fi

if [[ $# == 2 ]] && [[ "$tor_op" == "on" ]]; then
   echo
   echo -e "${minus} You can't use Tor alone"
   echo
   echo -e " USAGE $USAGE"
   echo
   exit 1
fi

# Passwd and no config file
if [[ "$pass_op" == "on" ]] && [[ "$conf_op" == "off" ]]; then
   echo
   echo -e "${minus} The option --passwd only is used together --config to uncrytp config file."
   echo
   exit 1
fi

# Files and no config file
if [[ "$fil_op" == "on" ]] && [[ "$conf_op" == "off" ]]; then
   echo
   echo -e "${minus} The option --files only is used together --config to uncrytp config file."
   echo
   exit 1
fi

#Incompatible search and config styles (for the moment)
if [[ "$search_op" == "on" ]] && [[ "$conf_op" == "on" ]]; then
   echo
   echo -e "${minus} The styles 'search' and 'config file' can be used at the same time."
   echo
   exit 1
fi


# Checking arguments
while [[ $# > 0 ]]; do
 parameter="$1"

 case $parameter in

    -c|--config)
       #read -r CONF_FILE <<< "$2"
       CONF_FILE="$2"
    shift
    ;;

    -m|--mode)
      if [[ $2 = "df" || $2 = "status" || $2 = "sync" || $2 = "up" || $2 = "down" ]]; then
          CHECK_MODE="$2"
       else
          echo
          echo -e "${minus} Only df, status, up, down and sync modes are accepted"
          echo
          echo -e " USAGE $USAGE"
          echo
          exit 1
       fi
    shift
    ;;

    -t|--tor)
       if [[ "$2" == "on" || "$2" == "off" ]]; then
          TOR_MODE="$2"
       else
          echo
          echo -e "${minus} Tor only accept on/off arguments"
          echo
          echo -e " USAGE $USAGE"
          echo
          exit 1
       fi
    shift
    ;;

    -f|--files)
      show_files="yes"
    #shift
    ;;

    -p|--passwd)
       if [[ -n "$2" ]] && [[ "$2" != "-"* ]]; then
          GPG_PW="$2"
          shift
       elif [[ -n "$2" ]] && [[ "$2" == "-"* ]]; then
          read -s -p "${plus} Enter GPG private key password: " GPG_PW
          echo
          #shift
       elif [[ -z "$2" ]]; then
          read -s -p "${plus} Enter GPG private key password: " GPG_PW
          echo
          #shift
       else
          echo "${minus} Error getting password"
          echo
          exit 1
       fi
    #shift
    ;;

    -s|--search)
       if [[ -z "$2" ]] || [[ "$2" == "-"* ]]; then
          echo
          echo -e "${minus} You have to provide a search dir"
          echo
          echo -e " USAGE $USAGE"
          echo
          exit 1
       elif [[ ! -d "$2" ]]; then
          echo
          echo -e "Search directory $S2 not found"
          echo
          exit 1
       elif [[ -d "$2" ]]; then
          SEARCH_DIR="$2"
          #shift
          if [[ -z "$3" ]] || [[ "$3" == "-"* ]];then
             read -e -p "${plus} Enter file name to search: " -i "$SEARCH_NAME" SEARCH_NAME
             shift
             SEARCH_MODE="on"
             echo
          elif [[ -n "$3" ]] && [[ "$3" != "-"* ]];then
             SEARCH_NAME="$3"*
             shift 2
             SEARCH_MODE="on"
          else
             echo "${minus} Error getting search name"
             echo
             exit 1
          fi
       else
          echo -e "${minus} Error in search mode"
          echo
          exit 1
       fi
    ;;
    *)
    echo
    echo -e "${minus} Unknown option ${txtred}$1${txtrst}"
    echo
    echo -e " USAGE $USAGE ${txtrst}"
    echo
    exit 1
    ;;
 esac
 shift
done

# Check mode empty
if [[ "$conf_op" == "on" ]] && [[ -z "$CHECK_MODE" ]]; then
    echo -e "${minus} You have to chose one mode to check"
    echo
    echo -e " USAGE mmega --config <path/to/conf_file> --mode <df|status|up|down|sync> [options"] 
    echo
    exit 1
fi

# -- Functions  -----------------------------------------------------------------------------------------------------

#Get info about file and set tmp file
get_info_file() {
 conf_filename=$(echo "$CONF_FILE" | rev | cut -d / -f1 | rev)
 conf_extension=${CONF_FILE##*.}
 conf_file_type=$(file $CONF_FILE | cut -d ' ' -f 3)
}

set_tmp_file(){
 ## encrypted mode
 if [ "$conf_extension" = "gpg" ] && [ "$conf_file_type" = "RSA" ]; then  ## only for RSA encrypted files
    echo -ne "${plus} Config file [${txtgrn}$conf_filename${txtrst}] "

    if [ -n "$GPG_PW" ];then
       tmp_conf_file=$(echo "$GPG_PW" | gpg --passphrase-fd 0 --no-tty --batch --yes -d $CONF_FILE 2>$TMP_DIR/id.pubkey)
    else
       tmp_conf_file=$(gpg -v --yes -d $CONF_FILE 2>$TMP_DIR/id.pubkey)
    fi

    # data from encrypted file (id key and mail)

    GPG_KEY=$(cat "$TMP_DIR/id.pubkey" | grep "ID" | cut -d ' ' -f 10 | cut -d , -f 1)
    MAIL_KEY=$(cat "$TMP_DIR/id.pubkey" | grep "@" | cut -d '<' -f 2 | cut -d '>' -f 1)

    #echo -e "[$MAIL_KEY]"
    echo -e

    #Check if tmp conf is empty
    if [[ -z "$tmp_conf_file" ]]; then
       echo -e "${minus} Error decrypting file"
       echo -e "[·] The file was encrypted by ${txtgrn}$MAIL_KEY ${txtrst}[Key ID ${txtgrn}$GPG_KEY${txtrst}]"
       echo
       exit 1
    fi

 ## tmp file mode
 elif [[ "$conf_file_type" = "text" ]] || [[ "$conf_file_type" = "Unicode" ]] && [[ "$SEARCH_MODE" = "on" ]]; then
    echo -e "${plus} Config file populated with accounts [${txtgrn}$conf_filename${txtrst}]"
    tmp_conf_file=$(cat $CONF_FILE)

    #Check if tmp conf is empty
    if [[ -z "$tmp_conf_file" ]]; then
       echo -e "${minus} Error reading config file"
       echo
       exit 1
    fi

 ## unencrypted mode
 elif [[ "$conf_file_type" = "text" ]] || [[ "$conf_file_type" = "Unicode" ]]; then
    echo -e "${excl} Config file [${txtylw}$conf_filename${txtrst}]"
    tmp_conf_file=$(cat $CONF_FILE)

    #Check if tmp conf is empty
    if [[ -z "$tmp_conf_file" ]]; then
       echo -e "${minus} Error reading config file"
       echo
       exit 1
    fi

 ## file not valid
 else
    echo -e "${minus} File not valid [${txtblk}$conf_filename${txtrst}]"
    echo
    exit 1
 fi
}

#Test file format
#empty lines and blank spaces
check_empty_lines() {
 empty_lines=0
 IFS=$'\n'

 for line in $tmp_conf_file;do
    if [[ -n "$( echo $line | grep -qxF '')" ]] || [[ -n "$( echo $line | grep -Ex '[[:space:]]+' )" ]];then
       empty_lines=$(( $empty_lines + 1 ))
       tmp_conf_file=$( echo "$tmp_conf_file" | sed '/^\s*$/d' )
    fi
 done

 if [[ $empty_lines != 0 ]]; then
    echo -e "${excl} ${txtylw}$empty_lines empty lines${txtrst} deleted in config file"
    #accounts_err=$(( $accounts_err + 1 ))
 fi
}

check_wrong_fields() {
 for line in $tmp_conf_file;do
    IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
    # Checking account mail
      if [[ ! "$username" = "$( echo $username | grep '[a-z, 0-9]@[a-z, 0-9]*...[a-z, 0-9]' )" ]];then
         tmp_conf_file=$( echo "$tmp_conf_file" | grep -v "$line")
         accounts_err=$(( $accounts_err + 1 ))
         echo -e "${excl} Wrong username [${txtblk}in $name${txtrst}]"
    # Check empty fields (username, passwd)
      elif [[ -z "$username" ]] || [[ -z "$passwd" ]];then
         tmp_conf_file=$( echo "$tmp_conf_file" | grep -v "$line")
         accounts_err=$(( $accounts_err + 1 ))
         echo -e "${excl} Empty username/password [${txtblk}in $name${txtrst}]"
      fi
 done
}

#check if config file is empty
check_empty_conf_file() {
if [[ -z "$tmp_conf_file" ]]; then
    echo -e "${minus} No valid accounts founded"
    echo
    exit 1
fi
}

# Net functions
get_ip() {
 IP=$(curl -s4 api.ipify.org)
 if [[ -z "$IP" ]]; then
    echo -e "\n${minus} Not internet connection"
    echo
    exit 1
 fi
}

get_dns() {
 if [ "${TOR_MODE}" = "off" ];then
    dns=$(cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f 2 | head -n1)
 elif [ "${TOR_MODE}" = "on" ];then
    dns=$(dig @127.0.0.1 -p 9053 3g2upl4pq6kufc4m.onion | grep SERVER | cut -d : -f 2 | cut -d '(' -f 1)
 fi
}

tor_on(){
 echo -ne "[·] ${txtblk}Checking binaries...${txtrst}"\\r
 #Check tor
  if [[ -z "$(command tor)" ]]; then
     echo -e "\n${minus} Tor binary not found"
     echo
     exit 1
  fi
 #Check torsocks
  if [[ -z "$(command torsocks)" ]]; then
     echo -e "\n${minus} Torsocks binary not found"
     echo
     exit 1
  fi
 #Check tor process
  if [[ -z "$(ps -aux | grep -o tor-service | uniq)" ]]; then
     echo -e "\n${minus} Tor is not running"
     exit 1
  fi

 . torsocks on &> /dev/null

 echo -ne "[·] ${txtblk}Checking           ${txtrst}"\\r

 #Check curl
  if [[ -z "$(command -v curl)" ]]; then
     echo -e "${minus} Curl binary not found. Skipped test"
  else #check tor connectivity
     echo -ne "[·] ${txtblk}Checking Tor...${txtrst}"\\r
     tor_check="$(curl -s4 https://check.torproject.org/ 2>&1 | grep -o Congratulations | head -n 1)"
     if [[ "$tor_check" = "Congratulations" ]]; then
        echo -ne "[·] ${txtblk}Tor is          ${txtrst}"\\r
        echo -ne "${plus} Tor is ${txtpur}on${txtrst} "
     else
        echo -e "${minus} Tor is not working"
        echo
        exit 1
     fi
  fi
}

tor_off() {
 . torsocks off &> /dev/null
 echo -ne "${excl} Tor is ${txtylw}off${txtrst} "
}

# Accounts functions
#number of accounts in config
set_accounts_number() {
 IFS=$'\n'
 accounts_num=$(echo "$tmp_conf_file" | wc -l)
}

#Declare variables and set them to 0
declare_variables() {
 accounts_num=$(echo "$tmp_conf_file" | wc -l)
 accounts_sync=0
 accounts_not_sync=0
 accounts_fail=0
 accounts_empty=0
 #accounts_err=0

 total_space=0
 total_free=0
 total_used=0

 num_to_up=0
 num_to_down=0

 total_files_to_upload=0
 total_files_to_download=0
 total_processed=0
}

# Cut name to 10 letters
cut_name() {
 if [[ "$name" = "$( echo $name | grep -Ez '[^/]{10}$' )" ]]; then
    name=$(echo "$name" | cut -b 1-10)
 fi
}

# Get data from a line
get_data() {
 printf " %-16s  %-20s\r" " ${point_blk}" "${txtblk}Getting data...${txtrst}"

 data_num=$(megadf -u $username -p "$passwd" 2>&1 | grep 'Total\|Free\|Used') #in bytes

 if [[ -z "$data_num" ]];then
    error_data_num=1
 else
    total_num=$(echo "$data_num" | grep  Total | cut -d ' ' -f 2)
    total="$(numfmt --to=iec --format='% f' $total_num )"

    free_num=$(echo "$data_num" | grep  Free | cut -d ' ' -f 3)
    free="$(numfmt --to=iec --format='%f' $free_num )"

    used_num=$(echo "$data_num" | grep  Used | cut -d ' ' -f 3)

    total_space=$(($total_space + $total_num))
    total_free=$(($total_free + $free_num))
    total_used=$(($total_used + $used_num))
 fi
}

# Get total bytes and tranform humand friendly
get_sum_hf() {
 Total_sum="$(numfmt --to=iec --format='%f' $total_space )"
 Free_sum="$(numfmt --to=iec --format='%f' $total_free )"
 Used_sum="$(numfmt --to=iec --format='%f' $total_used )"
}

# get files from local and remote directories. Tmp files will be created
get_files() {
 if [[ ! -d "$local_dir" ]];then
    num_to_up=0
    total_files_to_upload=$(($total_files_to_upload + $num_to_up))

    num_to_down=0
    total_files_to_download=$(($total_files_to_download + $num_to_down))

    num_total=0
    total_processed=$(($total_processed + $num_total))

 else
   printf " %-16s  %-20s\r" " ${varrows_down_blk}" "${txtblk}Getting files...${txtrst}"
   #get files to upload
   megacopy -u $username -p "$passwd" --dryrun --reload --local "$local_dir" --remote "$remote_dir" 2>&1 | grep ^F | cut -d ' ' -f 2- > "$TMP_DIR"/files_to_upload_$name
   num_to_up="$(grep -c $remote_dir $TMP_DIR/files_to_upload_$name)"
   total_files_to_upload=$(($total_files_to_upload + $num_to_up))
     #Encrypt
     if [ "$conf_extension" = "gpg" ] && [ "$conf_file_type" = "RSA" ];then
        gpg -e --no-tty --batch --yes -r $GPG_KEY $TMP_DIR/files_to_upload_$name
        rm -f $TMP_DIR/files_to_upload_$name
     fi

   #get files to download
   megacopy -u $username -p "$passwd" --dryrun --reload --download --local "$local_dir" --remote "$remote_dir" 2>&1 | grep ^F | cut -d ' ' -f 2- > "$TMP_DIR"/files_to_download_$name
   num_to_down="$(grep -c $local_dir $TMP_DIR/files_to_download_$name)"
   total_files_to_download=$(($total_files_to_download + $num_to_down))
     #Encrypt
     if [ "$conf_extension" = "gpg" ] && [ "$conf_file_type" = "RSA" ];then
        gpg -e --no-tty --batch --yes -r $GPG_KEY $TMP_DIR/files_to_download_$name
        rm -f $TMP_DIR/files_to_download_$name
     fi

   #get total files in cloud
   megacopy -u $username -p "$passwd" --dryrun --reload --download --local "$TMP_DIR" --remote "$remote_dir" 2>&1 | grep ^F | cut -d ' ' -f 2-  > "$TMP_DIR"/total_files_$name
   num_total="$(grep -c $TMP_DIR $TMP_DIR/total_files_$name)"
   total_processed=$(($total_processed + $num_total))
     #Encrypt
     if [ "$conf_extension" = "gpg" ] && [ "$conf_file_type" = "RSA" ];then
        gpg -e --no-tty --batch --yes -r $GPG_KEY $TMP_DIR/total_files_$name
        rm -f $TMP_DIR/total_files_$name
     fi
 fi
}

# Print status and get accounts to sync
get_status() {
 printf " %-16s %-20s\r" " ${point_blk}" "${txtblk}Getting status...${txtrst}"
 if [[ "$error_data_num" = 1 ]]; then
    accounts_err=$(($accounts_err + 1))
    acc_to_sync=$( echo "$acc_to_sync" | grep -v "$line")
    status="${circle_blk}"
    name="${txtblk}$name"
    total=""
    free=""
    num_total=""
    sync=""
    task="wrong username/passwd ${txtrst}"
    error_data_num=0 # counter to 0
 elif [[ "${SEARCH_MODE}" == "on" ]]; then
    accounts_check=$(($accounts_check + 1))
    status="${circle_grn}"
    num_total=
    sync=
    task="$username"
 elif [[ "${CHECK_MODE}" = "df" ]]; then
    accounts_check=$(($accounts_check + 1))
    status="${circle_grn}"
    num_total=
    sync=
    task="${username}"
 elif [[ ! -d "$local_dir" ]]; then
    accounts_fail=$(($accounts_fail + 1))
    acc_to_sync=$( echo "$acc_to_sync" | grep -v "$line")
    status="${circle_red}"
    num_total=""
    sync="fail"
    task="wrong local dir"
 elif [ ! -z "$data_num" ] && [ "$num_to_up" = 0 ] && [ "$num_to_down" = 0 ] && [ "$num_total" != 0 ]; then
    accounts_sync=$(($accounts_sync + 1))
    acc_to_sync=$( echo "$acc_to_sync" | grep -v "$line")
    status="${circle_grn}"
    sync="yes"
    task="${good_grn}"
 elif [ ! -z "$data_num" ] && [ "$num_total" = 0 ] && [ "$free_num" != "$total_num" ]; then
    accounts_fail=$(($accounts_fail + 1))
    acc_to_sync=$( echo "$acc_to_sync" | grep -v "$line")
    status="${circle_red}"
    num_total=""
    sync="fail"
    task="wrong remote dir"
 elif [ ! -z "$data_num" ] && [ "$num_total" = 0 ] && [ "$free_num" = "$total_num" ] && [ "$num_to_up" = 0 ]; then
    accounts_empty=$(($accounts_empty + 1))
    acc_to_sync=$( echo "$acc_to_sync" | grep -v "$line")
    status="${circle_grn}"
    num_total=""
    sync="-"
    task="empty account"
 else
    accounts_not_sync=$(($accounts_not_sync + 1))
    status="${circle_ylw}"
    sync="no"
    task=$(printf "%-2s %-5s %-2s %-5s\n" "$up_arrow_red" "$num_to_up" "$down_arrow_grn" "$num_to_down")
 fi
}

get_accounts_stat() {
 accounts_con=$(($accounts_check + $accounts_sync + $accounts_not_sync + $accounts_empty + $accounts_fail))
 accounts_total_checked=$(($accounts_err + $accounts_con))

 if [ $accounts_err != 0 ] && [ "${SEARCH_MODE}" = "on" ]; then
    status="$circle_blk"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %4s %-3s\n"  "${txtblk}error" "$accounts_err ${txtrst}"
 elif [ "${SEARCH_MODE}" = "on" ]; then
    status="$circle_grn"
    printf " %-16s %-15s\n" " $status" "$accounts_check/$accounts_total_checked connected"
    #printf " %4s %-3s %5s %-3s\n" "${txtgrn}check" "$accounts_check${txtrst}"
 elif [ $accounts_err != 0 ] && [ "${CHECK_MODE}" = "df" ]; then
    status="$circle_blk"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %4s %-3s\n"  "${txtblk}error" "$accounts_err ${txtrst}"
 elif [ "${CHECK_MODE}" = "df" ]; then
    status="$circle_grn"
    printf " %-16s %-15s\n" " $status" "$accounts_check/$accounts_total_checked connected"
    #printf " %4s %-3s %5s %-3s\n" "${txtgrn}check" "$accounts_check${txtrst}"
 elif [ $accounts_err != 0 ] && [ "${CHECK_MODE}" != "df" ]; then
    status="$circle_blk"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %5s %-3s %5s %-3s %5s %-3s %5s %-3s %5s %-3s\n" "${txtgrn}sync" "$accounts_sync" "${txtylw}unsyn" "$accounts_not_sync" "${txtred}fail" "$accounts_fail" "${txtblk}error" "$accounts_err${txtrst}"
 elif [ $accounts_fail != 0 ]; then
    status="$circle_ylw"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %5s %-3s %5s %-3s %5s %-3s %5s %-3s\n" "${txtgrn}sync" "$accounts_sync" "${txtylw}unsyn" "$accounts_not_sync" "${txtred}fail" "$accounts_fail${txtrst}"
 elif [ $accounts_empty != 0 ]; then
    status="$circle_grn"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %5s %-3s %5s %-3s %5s %-3s\n" "${txtgrn}sync" "$accounts_sync" "${txtylw}unsyn" "$accounts_not_sync" "${txtred}fail" "$accounts_fail${txtrst}" "${txtblu}empty" "$accounts_empty${txtrst}"
 elif [ $accounts_not_sync != 0 ]; then
    status="$circle_grn"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %5s %-3s %5s %-3s\n" "${txtgrn}sync" "$accounts_sync" "${txtylw}unsyn" "$accounts_not_sync ${txtrst}"
 else
    status="$circle_grn"
    printf " %-16s %-15s" " $status" "$accounts_con/$accounts_total_checked connected"
    printf " %5s %-3s\n" "${txtgrn}sync" "$accounts_sync ${txtrst}"
 fi
 echo " ______________________________________________________________________"
 echo
}

print_results() {

 if [[ "$SEARCH_MODE" == "on" ]];then
      printf " %-16s  %-10s  %6s  %6s  %-18s  %-18s\n" " $status" "$name" "$total" "$free" "$username" "$path"
 else
    test=$(echo $task | grep "username/passwd")

    if [ "$task" = "$test" ];then
       printf " %-16s  %-15s  %6s  %6s  %6s  %-6s  %-22s\n" " $status" "$name" "$total" "$free" "$num_total" " $sync" "$task"
    else
       printf " %-16s  %-10s  %6s  %6s  %6s  %-6s  %-22s\n" " $status" "$name" "$total" "$free" "$num_total" " $sync" "$task"
    fi
 fi
}

print_summary() {
 #space and files
 if [ $accounts_not_sync != 0 ]; then
    task_sum=$(printf "%-2s %-5s %-2s %-5s\n" "$up_arrow_red" "$total_files_to_upload" "$down_arrow_grn" "$total_files_to_download")
    printf " %-3s  %10s  %6s  %6s  %6s  %-6s  %-22s\n" "" "" "$Total_sum" "$Free_sum" "$total_processed" "" "$task_sum"
    printf " %-3s  %6s  %10s  %6s  %6s  %-6s  %-22s\n" "" "" "Used $Used_sum" "" "" "" ""
 else
    task_sum=
    total_processed=
    printf " %-3s  %10s  %6s  %6s  %6s  %-6s  %-22s\n" "" "" "$Total_sum" "$Free_sum" "$total_processed" "" "$task_sum"
    printf " %-3s  %6s  %10s  %6s  %6s  %-6s  %-22s\n" "" "" "Used $Used_sum" "" "" "" ""
 fi
}


get_number_of_files() {
 # encrypted
 if [ "$conf_file_type" = "RSA" ]; then
    #get num to upload and donwload
    num_to_up=$(gpg --no-tty --batch --yes -d "$TMP_DIR/files_to_upload_$name.gpg" 2>/dev/null | grep -c "$remote_dir" )
    num_to_down=$(gpg --no-tty --batch --yes -d "$TMP_DIR/files_to_download_$name.gpg" 2>/dev/null | grep -c "$local_dir" )

 #unencrypted
 elif [[ "$conf_file_type" = "text" ]] || [[ "$conf_file_type" = "Unicode" ]]; then
    #get num to upload and donwload
    num_to_up="$(grep -c $remote_dir $TMP_DIR/files_to_upload_$name)"
    num_to_down="$(grep -c $local_dir $TMP_DIR/files_to_download_$name)"

 #file not valid
 else
    echo -e "${minus} Error getting number of files"
    echo
    exit 1
 fi
}

get_list_of_files() {
 printf " %-3s %-60s\n" "·" "Files ${txtund}${txtblu}$name                                           ${txtrst}"
# encrypted
 if [ "$conf_file_type" = "RSA" ]; then
    #get num to upload and donwload
    files_to_up=$(gpg --no-tty --batch --yes -d "$TMP_DIR/files_to_upload_$name.gpg" 2>/dev/null | grep "$remote_dir" )
    files_to_down=$(gpg --no-tty --batch --yes -d "$TMP_DIR/files_to_download_$name.gpg" 2>/dev/null | grep "$local_dir" )

 #unencrypted
 elif [[ "$conf_file_type" = "text" ]] || [[ "$conf_file_type" = "Unicode" ]]; then
    #get num to upload and donwload
    files_to_up="$(grep $remote_dir $TMP_DIR/files_to_upload_$name)"
    files_to_down="$(grep $local_dir $TMP_DIR/files_to_download_$name)"
 #file not valid
 else
    echo -e "${minus} Error getting list of files"
    echo
    exit 1
 fi

   #Upload
   if [[ "$num_to_up" != 0  ]]; then
      printf " %-4s %-40s\n" "$up_arrow_red" " ${txtred}$num_to_up files ${txtrst}to be uploaded"
      echo -e "$files_to_up"
   fi

   #Download
   if [[ "$num_to_down" != 0  ]];then
      printf " %-4s %-40s\n" "$down_arrow_grn" " ${txtgrn}$num_to_down files ${txtrst}to be downloaded"
      echo -e "$files_to_down"
   fi
 printf " %-4s %-60s\n" "${txtblu}· " "${txtblu}${txtund}                                                                   ${txtrst}"
 echo
}

show_files(){
 if [[ "$accounts_not_sync" == 0 ]] && [[ $accounts_fail != 0  ||  $accounts_err != 0 ]];then
    printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " No files to sycn but $(( $accounts_fail + $accounts_err )) accounts failed to be check"
    echo
 elif [[ $accounts_not_sync != 0 ]] && [[ $accounts_fail != 0 ||  $accounts_err != 0 ]];then
    printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " $(( $accounts_fail + $accounts_err )) accounts failed. No files will be shown"
    echo
    for line in $acc_to_sync;do
       IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
       cut_name
       get_number_of_files
       get_list_of_files
    done
    printf "  %-4s %-40s\n" "${circle_grn}" " Files checked${txtrst}"
    echo -e "${txtblk} _____________________________________________________________________${txtrst}"
    echo

 elif [ $accounts_not_sync != 0 ];then
    printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " Showing files..."
    echo
    for line in $acc_to_sync;do
       IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
       cut_name
       get_number_of_files
       get_list_of_files
    done
    printf "  %-4s %-40s\n" "${txtgrn} ·" " Files checked${txtrst}"
    echo -e "${txtblk} _____________________________________________________________________${txtrst}"
    echo

 elif [ $accounts_not_sync = 0 ];then
    printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " All accounts are synchronized, no files to show."
    echo
 fi
}

upload(){
 printf " %-4s %-40s\n" "$up_arrow_red" " ${txtred}Uploading $num_to_up files${txtrst}"
 megacopy --no-progress -u $username -p "$passwd" --reload --local $local_dir --remote $remote_dir 2>&1 | grep -v ERROR
}

download(){
 printf " %-4s %-40s\n" "$down_arrow_grn" " ${txtgrn}Downloading $num_to_down files${txtrst}"
 megacopy --no-progress -u $username -p "$passwd" --reload --download --local $local_dir --remote $remote_dir 2>&1 | grep -v ERROR
}

sync(){
 printf " %-4s %-60s\n" "$varrows_down_bold" " Synchronizing ${txtund}${txtblu}$name                                           ${txtrst}"
 #Synchro simple megacopy
   #Upload
   if [[ "$num_to_up" != 0  ]]; then
      upload
   fi
   #Download
   if [[ "$num_to_down" != 0  ]];then
      download
   fi
 printf " %-4s %-60s\n" "${hrarrows_blu_bold}" " ${txtblu}Done ${txtund}                                                              ${txtrst}"
 echo
}

#####################################################################################################################
## -- START ---------------------------------------------------------------------------------------

#Hostname
echo -e "${plus} Host ${txtgrn}$HOST${txtrst}"


#if search mode on aqui
# -- MODE SEARCH ----------------------------------------------------------------------------------------------------------
if [[ "${SEARCH_MODE}" = "on" ]]; then
   echo -e "${plus} Searching ${txtgrn}$SEARCH_NAME ${txtrst}config files in ${txtgrn}$SEARCH_DIR${txtrst}"

   conf_files=$(find "$SEARCH_DIR" -path '*Trash*' -prune -o -name "$SEARCH_NAME" 2>&1 | grep "$SEARCH_NAME" )
   conf_files_same=$(find "$SEARCH_DIR" -type f -path '*Trash*' -prune -o -name "$SEARCH_NAME" -exec md5sum "{}" ";" 2>&1 | grep "$SEARCH_NAME" | sort | uniq --all-repeated=separate -w 33 | cut -c 35-)

   ## Test if conf_files_same is empty
   if [[ -n "$conf_files_same" ]]; then
      echo -e "${excl} There are duplicate config files. Stat not will be right"
   fi

   # create tmp conf file
   touch $TMP_DIR/conf_file_from_search

   #obtein variables from each file
   for line in $conf_files; do
       #Check conf file
       if [[ "$( cat $line | grep -o '\[Login\]\|Username\|Password' | tr -d '\n' )" == "[Login]UsernamePassword" ]]; then
          # variables
          name=$(echo "$line" | rev | cut -d / -f1 | rev | head -c 10)
          path=$(echo "$line" | rev | cut -d / -f 2- | rev )
          username=$(cat $line | grep Username | cut -d = -f2 | tr -d "[:space:]")
          passwd="$(cat $line | grep Password | cut -d = -f2 | cut -d ' ' -f2- )"
          cut_name

          #populate tmp conf file
          echo "$name,$username,$passwd," >> $TMP_DIR/conf_file_from_search

        else
           echo "Error reading config file [$line]"
        fi
    done

   #Set CONF_FILE
   CONF_FILE=$TMP_DIR/conf_file_from_search

   get_info_file
   set_tmp_file

   set_accounts_number
   acc_t1=$accounts_num

   check_empty_lines
   check_wrong_fields
   check_empty_conf_file

   # check Tor
   if [[ "$TOR_MODE" = "on" ]];then
      get_dns
      tor_on
      get_ip
      echo -e "[IP ${txtgrn}$IP${txtrst} DNS${txtblu}$dns${txtrst}] "
   elif [[ "$TOR_MODE" = "off" ]];then
      tor_off
      get_ip
      get_dns
      echo -e "[IP ${txtylw}$IP${txtrst} DNS ${txtblu}$dns${txtrst}]"
    fi


   echo -ne "${plus} Checking ${txtgrn}mega files${txtrst} "
   declare_variables

   if [ $accounts_num != $acc_t1 ];then
      echo -e "[${txtylw}$accounts_num${txtrst} accounts ${txtblk}$accounts_err errors ${txtrst}]"
   else
      echo -e "[${txtgrn}$accounts_num${txtrst} accounts]"
   fi
   echo

   #printf " %-3s  %-10s  %-6s  %-6s  %-6s  %-6s  %-22s\n" "___" "name______" "space_" "free__" "files_" "sync__" "username_____________"
   printf " %-3s  %-10s  %-6s  %-6s  %-18s  %-18s\n" "___" "name______" "space_" "free__" "username_________" "path______________"

   echo

   for line in $tmp_conf_file;do
      IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
        cut_name
        get_data
        get_status
        print_results
   done

   printf " %-3s  %-10s  %-6s  %-6s  %-18s  %-18s\n" "___" "__________" "_____" "______" "_________________" "_________________"

   get_sum_hf
   print_summary
   echo
   get_accounts_stat

   declare_variables
   CONF_FILE=

fi


if [[ -n "$CHECK_MODE" ]]; then ###################################################################################

get_info_file
set_tmp_file

set_accounts_number
acc_t1=$accounts_num

check_empty_lines
check_wrong_fields
check_empty_conf_file

# check Tor
if [[ "$TOR_MODE" = "on" ]];then
   get_dns
   tor_on
   get_ip
   echo -e "[IP ${txtgrn}$IP${txtrst} DNS${txtblu}$dns${txtrst}] "
elif [[ "$TOR_MODE" = "off" ]];then
   tor_off
   get_ip
   get_dns
   echo -e "[IP ${txtylw}$IP${txtrst} DNS ${txtblu}$dns${txtrst}]"
fi

# check if show_files is active. Only work with status and sync modes
if [[ "$CHECK_MODE" = "df" ]] && [[ "$show_files" == "yes" ]]; then
   echo "${excl} In disk free mode no files will be show"
fi

## Check mode DISK FREE ---------------------------------------
if [[ "${CHECK_MODE}" = "df" ]];then
   echo -ne "${plus} Checking ${txtgrn}disk free${txtrst} "
   declare_variables

   if [ $accounts_num != $acc_t1 ];then
      echo -e "[${txtylw}$accounts_num${txtrst} accounts ${txtblk}$accounts_err errors ${txtrst}]"
   else
      echo -e "[${txtgrn}$accounts_num${txtrst} accounts]"
   fi
   echo

   printf " %-3s  %-10s  %-6s  %-6s  %-6s  %-6s  %-22s\n" "___" "name______" "space_" "free__" "files_" "sync__" "task_________________"
   echo

   for line in $tmp_conf_file;do
      IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
        cut_name
        get_data
        get_status
        print_results
   done

   printf " %-3s  %-10s  %6s  %6s  %6s  %-6s  %-22s\n" "___" "__________" "______" "______" "______" "______" "_____________________"
   get_sum_hf
   print_summary
   echo
   get_accounts_stat

## Check mode STATUS -------------------------------------------
elif [[ "${CHECK_MODE}" = "status" ]]; then
   echo -ne "${plus} Checking ${txtgrn}status${txtrst} "
   declare_variables

   if [ $accounts_num != $acc_t1 ];then
      echo -e "[${txtylw}$accounts_num${txtrst} accounts ${txtblk}$accounts_err errors${txtrst}]"
   else
      echo -e "[${txtgrn}$accounts_num${txtrst} accounts]"
   fi
   echo

   printf " %-3s  %-10s  %-6s  %-6s  %-6s  %-6s  %-22s\n" "___" "name______" "space_" "free__" "files_" "sync__" "task_________________"
   echo

   acc_to_sync=$(echo "$tmp_conf_file")

   for line in $tmp_conf_file;do
      IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
        cut_name
        get_data
        get_files
        get_status
        print_results
   done

   printf " %-3s  %-10s  %6s  %6s  %6s  %-6s  %-22s\n" "___" "__________" "______" "______" "______" "______" "_____________________"
   get_sum_hf
   print_summary
   echo
   get_accounts_stat

   # show files
   if [[ "$show_files" == "yes" ]] && [[ $accounts_not_sync != 0 ]]; then
      show_files
   fi

## Check mode DOWNLOAD ----------------------------------------------
elif [[ "${CHECK_MODE}" = "down" ]]; then
   echo -ne "${plus} ${txtgrn}Downloading${txtrst} "
   declare_variables

   if [ $accounts_num != $acc_t1  ];then
      echo -e "[${txtylw}$accounts_num${txtrst} accounts ${txtblk}$accounts_err errors${txtrst}]"
   else
      echo -e "[${txtgrn}$accounts_num${txtrst} accounts]"
   fi
   echo

   printf " %-3s  %-10s  %-6s  %-6s  %-6s  %-6s  %-22s\n" "___" "name______" "space_" "free__" "files_" "sync__" "task_________________"
   echo

   acc_to_sync=$(echo "$tmp_conf_file")

   for line in $tmp_conf_file;do
      IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
        cut_name
        get_data
        get_files
        get_status
        print_results
   done

   printf " %-3s  %-10s  %6s  %6s  %6s  %-6s  %-22s\n" "___" "__________" "______" "______" "______" "______" "_____________________"
   get_sum_hf
   print_summary
   echo
   get_accounts_stat

   # show files
   if [[ "$show_files" == "yes" ]] && [[ $accounts_not_sync != 0 ]]; then
      show_files
   fi

   #download
   if [[ $accounts_not_sync = 0 ]] && [[ $accounts_fail != 0 || $accounts_err != 0 ]];then
      printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " All accounts sycn but $(( $accounts_fail + $accounts_err )) accounts failed to be check."
   elif [[ $accounts_not_sync != 0 ]] && [[ $accounts_fail != 0 || $accounts_err != 0 ]];then
      printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " $(( $accounts_fail + $accounts_err )) accounts failed to be check and not will downloaded. Downloading accounts..."
      echo
      for line in $acc_to_sync;do
         IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
         cut_name
         get_number_of_files

         if [[ "$num_to_down" != 0  ]];then
            printf " %-4s %-60s\n" "${down_arrow_grn}" " Downloading ${txtund}${txtblu}$name                                           ${txtrst}"
            download
            printf " %-4s %-60s\n" "${down_arrow_blu}" " ${txtblu}Done ${txtund}                                                              ${txtrst}"
            echo
         fi

      done
      printf "  %-4s %-40s\n" "${circle_grn}" " Accounts downloaded"
      echo " _____________________________________________________________________"

   elif [ $accounts_not_sync != 0 ];then
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " Downloading accounts..."
      echo
      for line in $acc_to_sync;do
         IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
         cut_name
         get_number_of_files

         if [[ "$num_to_down" != 0  ]];then
            printf " %-4s %-60s\n" "${down_arrow_grn}" " Downloading ${txtund}${txtblu}$name                                           ${txtrst}"
            download
            printf " %-4s %-60s\n" "${txtblu}${down_arrow} " " ${txtblu}Done ${txtund}                                                              ${txtrst}"
            echo
         fi

      done
      printf "  %-4s %-40s\n" "${circle_grn}" " Accounts downloaded"
      echo " _____________________________________________________________________"

   elif [ $accounts_not_sync = 0 ];then
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " All accounts are synchronized. Nothing to download."
   fi


## Check mode UPLOAD ----------------------------------------------
elif [[ "${CHECK_MODE}" = "up" ]]; then
   echo -ne "${plus} ${txtgrn}Uploading${txtrst} "
   declare_variables

   if [ $accounts_num != $acc_t1  ];then
      echo -e "[${txtylw}$accounts_num${txtrst} accounts ${txtblk}$accounts_err errors${txtrst}]"
   else
      echo -e "[${txtgrn}$accounts_num${txtrst} accounts]"
   fi
   echo

   printf " %-3s  %-10s  %-6s  %-6s  %-6s  %-6s  %-22s\n" "___" "name______" "space_" "free__" "files_" "sync__" "task_________________"
   echo

   acc_to_sync=$(echo "$tmp_conf_file")

   for line in $tmp_conf_file;do
      IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
        cut_name
        get_data
        get_files
        get_status
        print_results
   done

   printf " %-3s  %-10s  %6s  %6s  %6s  %-6s  %-22s\n" "___" "__________" "______" "______" "______" "______" "_____________________"
   get_sum_hf
   print_summary
   echo
   get_accounts_stat

   # show files
   if [[ "$show_files" == "yes" ]] && [[ $accounts_not_sync != 0 ]]; then
      show_files
   fi

   #upload
   if [[ $accounts_not_sync = 0 ]] && [[ $accounts_fail != 0 || $accounts_err != 0 ]];then
      printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " All accounts sycn but $(( $accounts_fail + $accounts_err )) accounts failed to be check."
   elif [[ $accounts_not_sync != 0 ]] && [[ $accounts_fail != 0 || $accounts_err != 0 ]];then
      printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " $(( $accounts_fail + $accounts_err )) accounts failed to be check and not will uploaded. Uploading accounts..."
      echo
      for line in $acc_to_sync;do
         IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
         cut_name
         get_number_of_files

         if [[ "$num_to_up" != 0  ]];then
            printf " %-4s %-60s\n" "${up_arrow_red}" " Uploading ${txtund}${txtblu}$name                                           ${txtrst}"
            upload
            printf " %-4s %-60s\n" "${up_arrow_blu}" " ${txtblu}Done ${txtund}                                                              ${txtrst}"
            echo
         fi

      done
      printf "  %-4s %-40s\n" "${circle_grn}" " Accounts uploaded"
      echo " _____________________________________________________________________"

   elif [ $accounts_not_sync != 0 ];then
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " Uploading accounts..."
      echo
      for line in $acc_to_sync;do
         IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
         cut_name
         get_number_of_files

         if [[ "$num_to_up" != 0  ]];then
            printf " %-4s %-60s\n" "${up_arrow_red}" " Uploading ${txtund}${txtblu}$name                                           ${txtrst}"
            upload
            printf " %-4s %-60s\n" "${txtblu}${up_arrow} " " ${txtblu}Done ${txtund}                                                              ${txtrst}"
            echo
         fi

      done
      printf "  %-4s %-40s\n" "${circle_grn}" " Accounts downloaded"
      echo " _____________________________________________________________________"

   elif [ $accounts_not_sync = 0 ];then
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " All accounts are synchronized. Nothing to upload."
   fi

## Check mode SYNC ----------------------------------------------
elif [[ "${CHECK_MODE}" = "sync" ]]; then
   echo -ne "${plus} ${txtgrn}Synchronizing${txtrst} "
   declare_variables

   if [ $accounts_num != $acc_t1  ];then
      echo -e "[${txtylw}$accounts_num${txtrst} accounts ${txtblk}$accounts_err errors${txtrst}]"
   else
      echo -e "[${txtgrn}$accounts_num${txtrst} accounts]"
   fi
   echo

   printf " %-3s  %-10s  %-6s  %-6s  %-6s  %-6s  %-22s\n" "___" "name______" "space_" "free__" "files_" "sync__" "task_________________"
   echo

   acc_to_sync=$(echo "$tmp_conf_file")

   for line in $tmp_conf_file;do
      IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
        cut_name
        get_data
        get_files
        get_status
        print_results
   done

   printf " %-3s  %-10s  %6s  %6s  %6s  %-6s  %-22s\n" "___" "__________" "______" "______" "______" "______" "_____________________"
   get_sum_hf
   print_summary
   echo
   get_accounts_stat

   # show files
   if [[ "$show_files" == "yes" ]] && [[ $accounts_not_sync != 0 ]]; then
      show_files
   fi

   #Sync print
   if [[ $accounts_not_sync = 0 ]] && [[ $accounts_fail != 0 || $accounts_err != 0 ]];then
      printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " All accounts sycn but $(( $accounts_fail + $accounts_err )) accounts failed to be check."
   elif [[ $accounts_not_sync != 0 ]] && [[ $accounts_fail != 0 || $accounts_err != 0 ]];then
      printf "  %-4s %-40s\n" "${txtylw}$right_arrow${txtrst}" " $(( $accounts_fail + $accounts_err )) accounts failed to be check and not will synchronized"
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " Synchroning accounts..."
      echo
      for line in $acc_to_sync;do
         IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
         cut_name
         get_number_of_files
         sync
      done
      printf "  %-4s %-40s\n" "${circle_grn}" " Accounts synchronized"
      echo " _____________________________________________________________________"

   elif [ $accounts_not_sync != 0 ];then
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " Synchroning accounts..."
      echo
      for line in $acc_to_sync;do
         IFS=, read name username passwd local_dir remote_dir trash <<< "$line"
         cut_name
         get_number_of_files
         sync
      done
      printf "  %-4s %-40s\n" "${circle_grn}" " Accounts synchronized"
      echo " _____________________________________________________________________"

   elif [ $accounts_not_sync = 0 ];then
      printf "  %-4s %-40s\n" "${txtgrn}$right_arrow${txtrst}" " All accounts are synchronized"
   fi

fi # end big loop modes

fi # end bigger loop styles ############################################################################################################


if [[ "$CHECK_MODE" != "df" && "$SEARCH_MODE" == "off"  ]]; then
   echo -e " ${txtund}                                                                      ${txtrst}"
   echo
fi

exit 0
