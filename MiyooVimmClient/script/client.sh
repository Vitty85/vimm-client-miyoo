typeset -x mydir=$(pwd)
typeset -x sysdir=/mnt/SDCARD/.tmp_update
typeset -x miyoodir=/mnt/SDCARD/miyoo
typeset -x LD_LIBRARY_PATH="$mydir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
typeset -x PATH="$sysdir/bin:$PATH"

cd $mydir

init_static_globals() {
	typeset -gr DIALOG=$mydir/bin/dialog || { print "ERROR: 'dialog' not found" ; return 1 }

	typeset -gr MAXHEIGHT=$(( $LINES - 0 ))
	typeset -gr MAXWIDTH=$(( $COLUMNS - 0 ))
	typeset -gr CHOICE_HEIGHT=12

	typeset -gr DIALOG_OK=0
	typeset -gr DIALOG_CANCEL=1
}

shortdialoginfo () {
    $DIALOG --no-lines --infobox "$@" 3 30
}

longdialoginfo() {
    $DIALOG --no-lines --infobox "$@" 3 60
}

cleanup(){
	url=""
	response=""
	gameName=""
	mediaId=""
	console=""
	imageName=""
	imageFileName=""
	headers=""
	fileSize=""
	filePath=""
	list=""
	letter=""
	subs=""
	res=""
}

main() {
	init_static_globals
	cleanup
	while true; do
		mainmenu 
	done
}

mainmenu() {
TITLE="The Miyoo Mini Client for Vimm's Lair Portal!"
MENU="Choose one of the following options:"

OPTIONS=(1 "Search by Vault ID"
         2 "Search by Platform"
         3 "Search by Name"
		 4 "About"
         5 "Exit")

CHOICE=$($DIALOG --colors --no-lines \
				--clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

case $CHOICE in
        1)
			vaultId=$($DIALOG --no-lines --inputbox "Enter the Vault ID and press OK" 0 0 2>&1 >/dev/tty)
			if [ $? -eq 0 ]; then
            	search_vaultId
			fi
            ;;
        2)
            search_platform
            ;;
        3)
            search_name
            ;;
        4)
            longdialoginfo "Miyoo Vimm's Lair Client - Version: 1.1"
			sleep 2
            ;;
        5)
            longdialoginfo  "You quit Miyoo Vimm's Lair Client."
            sleep 1
            exit 0
            ;;
esac
}

search_vaultId() {
	if [ "$vaultId" = "" ]; then
		longdialoginfo "Please specify a valid Vault ID..."
		cleanup
		sleep 1
		return
	fi
	get_mediaId
	if [ "$mediaId" = "" ]; then
		longdialoginfo "Cannot find mediaId..."
		cleanup
		sleep 1
		return
	fi
	get_filePath
	get_gameName
	if [ "$gameName" = "" ]; then
		longdialoginfo "Cannot find game name..."
		cleanup
		sleep 1
		return
	fi
	get_imageName
	if [ "$imageFileName" = "" ]; then
		longdialoginfo "Cannot find game BoxArt..."
		sleep 1
	fi
	$($DIALOG --no-lines --yesno "Search result:\n\nFile:$gameName\nSize: $fileSize\nBoxArt: $imageFileName\nConsole: $console\nPath: $filePath\n\nPress Yes to confirm." 0 0 2>&1 >/dev/tty)
	if [ $? -ne 0 ]; then
		longdialoginfo "Download aborted..."
		cleanup
		sleep 1
		return
	fi
	download_game
	if [ "$res" = "" ]; then
		longdialoginfo "Game has been downloaded in: $filePath/$gameName"
		sleep 3
	fi
	cleanup
}

get_mediaId() {
	url="https://vimm.net/vault/$vaultId"
	response=$(curl -s -k $url)
	if [ $? -ne 0 ]; then
		longdialoginfo "Error on HTTP connection..."
		cleanup
		sleep 1
		return
	fi
	fileSize=$(echo "$response" | sed -n 's/.*download_size">\([^"]*\).*/\1/p' | sed -n 's/<.*//p')
	echo "$response" | tr ';' '\n' | grep -i "var media = .*" >> allMedia
	while IFS= read -r line; do
		id=$(echo "$line" | grep -o '"ID":[0-9]*' | awk -F':' '{print $2}')
		goodTitle=$(echo "$line" | grep -o '"GoodTitle":"[^"]*"' | awk -F'"' '{print $4}')
		row="$id) $goodTitle                                                "
		echo $row >> tmpFile
	done < allMedia
	list=$(cat tmpFile)
	rm -rf allMedia tmpFile
	numLines=$(echo "$list" | wc -l)
	if [ $numLines -gt 1 ]; then
		mediaId=$($DIALOG --no-lines --inputbox "Found more discs or versions:\n\n$list\n\nEnter the media ID and press OK" 0 0 2>&1 >/dev/tty)
		if [ $? -eq 0 ]; then
			if [ "$mediaId" = "" ]; then
				longdialoginfo "You didn't choose any media ID, the default one will be selected."
				sleep 1
				mediaId=$(echo "$response" | sed -n 's/.*mediaId" value="\([^"]*\).*/\1/p')
				return
			fi
			return
		fi
		longdialoginfo "You didn't choose any media ID, the default one will be selected."
		sleep 1
	fi
	mediaId=$(echo "$response" | sed -n 's/.*mediaId" value="\([^"]*\).*/\1/p')
}

get_filePath() {
	if [ "$console" = "" ]; then
		console=$(echo "$response" | sed -n 's/.*system" value="\([^"]*\).*/\1/p')
	fi
                                                
	case $console in
		"GB")            gameFolder="GB" platform="Nintendo_-_Game_Boy" ;;
		"GBC")           gameFolder="GBC" platform="Nintendo_-_Game_Boy_Color" ;;
		"GBA")           gameFolder="GBA" platform="Nintendo_-_Game_Boy_Advance" ;;
		"DS")            gameFolder="NDS" platform="Nintendo_-_Nintendo_DS" ;;
		"Atari2600")     gameFolder="ATARI" platform="Atari_-_2600" ;;
		"Atari5200")     gameFolder="FIFTYTWOHUNDRED" platform="Atari_-_5200" ;;
		"NES")           gameFolder="FC" platform="Nintendo_-_Nintendo_Entertainment_System" ;;
		"SMS")           gameFolder="MS" platform="Sega_-_Master_System_-_Mark_III" ;;
		"Atari7800")     gameFolder="SEVENTYEIGHTHUNDRED" platform="Atari_-_7800" ;;
		"Genesis")       gameFolder="MD" platform="Sega_-_Mega_Drive_-_Genesis" ;;
		"SNES")          gameFolder="SFC" platform="Nintendo_-_Super_Nintendo_Entertainment_System" ;;
		"32X")           gameFolder="THIRTYTWOX" platform="Sega_-_32X" ;;
		"PS1")           gameFolder="PS" platform="Sony_-_PlayStation" ;;
		"Lynx")          gameFolder="LYNX" platform="Atari_-_Lynx" ;;
		"GG")            gameFolder="GG" platform="Sega_-_Game_Gear" ;;
		"VB")            gameFolder="VB" platform="Nintendo_-_Virtual_Boy" ;;
		*)               gameFolder="" ;;
	esac
	filePath=/mnt/SDCARD/Roms/$gameFolder
}

get_gameName() {
	url=https://download3.vimm.net/download/?mediaId=$mediaId
	headers=$(curl -sI -X GET -H "Referer: https://vimm.net/vault/$vaultId" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0" --insecure $url)
	gameName=$(echo "$headers" | grep -o -E "filename=.*" | cut -d'=' -f2 | cut -d'"' -f2)
	sleep 1
}

get_imageName() {
	imageName=$(echo $gameName | sed 's/\(.*\)\..*/\1.png/g; s/ /%20/g; s/&/_/g')
	imageFileName=$(echo $gameName | sed 's/\(.*\)\..*/\1.png/g')
}

download_game() {
	response=$(curl -X GET -H "Referer: https://vimm.net/vault/$vaultId" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0"  --insecure -o "$gameName" $url)
	if [ $? -ne 0 ]; then
		longdialoginfo "Error while downloading game..."
		res="NOK"
		sleep 1
		return
	fi
	if [ -z "${gameName##*.7z*}" ]; then
		$($DIALOG --no-lines --yesno "Do you want to uncompress downloaded file?" 0 0 2>&1 >/dev/tty)
	        if [ $? -eq 0 ]; then
			7z x "$gameName"
			rm -rf "$gameName"
			gameName="${gameName%.*}"
		fi
	fi
	if [ -z "${gameName##*.zip*}" ]; then
		$($DIALOG --no-lines --yesno "Do you want to uncompress downloaded file?" 0 0 2>&1 >/dev/tty)
	        if [ $? -eq 0 ]; then
			7z x "$gameName" -o"${gameName%.*}"
			rm -rf "$gameName"
			gameName="${gameName%.*}"
		fi
	fi
	mv "$gameName" $filePath/.
	url=https://raw.githubusercontent.com/libretro-thumbnails/$platform/master/Named_Boxarts/$imageName
	response=$(curl -X GET --insecure -o "$imageFileName" $url)
	if [ $? -ne 0 ]; then
		longdialoginfo "Error while downloading BoxArt..."
		sleep 1	
		return
	fi
	mv "$imageFileName" $filePath/Imgs/.
}

browse_platform() {
    local options=(
        1 "Search by first chars"
        2 "Search by any substring"
        3 "Return"
    )

    local cmd=(
        $DIALOG --no-lines --title "Search by Platform" --menu "Choose an option" $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT 
    )
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	
	case $choice in
		1)
			letter=$($DIALOG --no-lines --inputbox "Enter the first letters or numbers and press OK" 0 0 2>&1 >/dev/tty)
			if [ $? -eq 0 ]; then
				if [ "$letter" = "" ]; then
					longdialoginfo "Please enter at least a valid char..."
					sleep 1
					browse_platform
				fi
            	list=$(awk -v cn="$console" -v le="^$letter" -F';' 'NR > 1 && $2 == cn && $1 ~ le {print $3") "substr($1, 1, 20)"                                      "}' db/database.csv)
			fi
			;;
		2)
			subs=$($DIALOG --no-lines --inputbox "Enter the substring and press OK" 0 0 2>&1 >/dev/tty)
			if [ $? -eq 0 ]; then
				if [ "$subs" = "" ]; then
					longdialoginfo "Please enter a valid substring..."
					sleep 1
					browse_platform
				fi
            	list=$(awk -v cn="$console" -F';' 'NR > 1 && $2 == cn {print $3") "substr($1, 1, 20)"                                              "}' db/database.csv | grep $subs)
			fi
			;;	
		3)
			search_platform
			;;
	esac
	if [ "$list" = "" ]; then
		longdialoginfo "No match found..."
		sleep 1
		browse_platform
	fi
	numLines=$(echo "$list" | wc -l)
	if [ $numLines -gt 20 ]; then
		list=$(echo "$list" | head -n 20)
	fi
	vaultId=$($DIALOG --no-lines --inputbox "Results (max 20):\n\n$list\n\nEnter the Vault Id and press OK" 0 0 2>&1 >/dev/tty)
	if [ $? -eq 0 ]; then
		search_vaultId
	fi
	browse_platform
}

search_platform() {
    local options=(
        1 "Atari 2600"
        2 "Atari 5200"
        3 "Atari 7200"
        4 "Lynx"
        5 "Nintendo - DS"
        6 "Nintendo - GameBoy"
        7 "Nintendo - GameBoy Advance"
        8 "Nintendo - GameBoy Color"
        9 "Nintendo - NES"
        10 "Nintendo - SNES"
        11 "Nintendo - Virtual Boy"
        12 "Sega - 32X"
        13 "Sega - Game Gear"
        14 "Sega - Master System"
        15 "Sega - Mega Drive"
        16 "Sony - Playstation"
        17 "Return"
    )

    local cmd=(
        $DIALOG --no-lines --title "Search by Platform" --menu "Select Platform Name" $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT 
    )
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

	case $choice in
		1)
			console="Atari2600"
			browse_platform
			;;
		2)
			console="Atari5200"
			browse_platform
			;;
        3)
			console="Atari7200"
			browse_platform
            ;;
        4)
			console="Lynx"
			browse_platform
            ;;
        5)
			console="DS"
			browse_platform
            ;;
        6)
			console="GB"
			browse_platform
            ;;
        7)
			console="GBA"
			browse_platform
            ;;
        8)
			console="GBC"
			browse_platform
            ;;
        9)
			console="NES"
			browse_platform
            ;;
        10)
			console="SNES"
			browse_platform
            ;;
        11)
			console="VB"
			browse_platform
            ;;
        12)
			console="32X"
			browse_platform
            ;;
        13)
			console="GG"
			browse_platform
            ;;
        14)
			console="SMS"
			browse_platform
            ;;
        15)
			console="Genesis"
			browse_platform
            ;;
        16)
			console="PS1"
			browse_platform
            ;;
		17)
			mainmenu
			;;
	esac
}

search_name(){
	local options=(
        1 "Search by first chars"
        2 "Search by any substring"
        3 "Return"
    )

    local cmd=(
        $DIALOG --no-lines --title "Search by Name" --menu "Choose an option" $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT 
    )
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	
	case $choice in
		1)
			letter=$($DIALOG --no-lines --inputbox "Enter the first letters or numbers and press OK" 0 0 2>&1 >/dev/tty)
			if [ $? -eq 0 ]; then
				if [ "$letter" = "" ]; then
					longdialoginfo "Please enter at least a valid char..."
					sleep 1
					search_name
				fi
            	list=$(awk -v le="^$letter" -F';' 'NR > 1 && $1 ~ le {print $3") "substr($1, 1, 20)" ("$2")                                     "}' db/database.csv)
			fi
			;;
		2)
			subs=$($DIALOG --no-lines --inputbox "Enter the substring and press OK" 0 0 2>&1 >/dev/tty)
			if [ $? -eq 0 ]; then
				if [ "$subs" = "" ]; then
					longdialoginfo "Please enter a valid substring..."
					sleep 1
					search_name
				fi
            	list=$(awk -F';' 'NR > 1 {print $3") "substr($1, 1, 20)" ("$2")                                              "}' db/database.csv | grep $subs)
			fi
			;;	
		3)
			mainmenu
			;;
	esac
	if [ "$list" = "" ]; then
		longdialoginfo "No match found..."
		sleep 1
		search_name
	fi
	numLines=$(echo "$list" | wc -l)
	if [ $numLines -gt 20 ]; then
		list=$(echo "$list" | head -n 20)
	fi
	vaultId=$($DIALOG --no-lines --inputbox "Results (max 20):\n\n$list\n\nEnter the Vault Id and press OK" 0 0 2>&1 >/dev/tty)
	if [ $? -eq 0 ]; then
		search_vaultId
	fi
	search_name
}

main