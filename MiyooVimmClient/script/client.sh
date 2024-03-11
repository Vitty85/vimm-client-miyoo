typeset -x mydir=$(pwd)
typeset -x sysdir=/mnt/SDCARD/.tmp_update
typeset -x miyoodir=/mnt/SDCARD/miyoo
typeset -x LD_LIBRARY_PATH="$mydir/lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
typeset -x PATH="$sysdir/bin:$PATH"

cd $mydir

getFileSize() {
	local input=$1
	local grandezze=('1' '1024' '1048576')
	local unit=('KB' 'MB' 'GB')
	local grandezza unit_calcolata result
	for i in $(seq ${#grandezze[@]} -1 1); do
		grandezza=${grandezze[$i - 1]}
		if [ "$input" -ge "$grandezza" ]; then
			unit_calcolata=${unit[$i - 1]}
			result=$((input * 10 / grandezza))
			fileSize="$((result / 10)) $unit_calcolata"
			return
		fi
	done
	fileSize=""
}

init_static_globals() {
	typeset -gr DIALOG=$mydir/bin/dialog || { print "ERROR: 'dialog' not found" ; return 1 }

	typeset -gr MAXHEIGHT=$(( $LINES - 0 ))
	typeset -gr MAXWIDTH=$(( $COLUMNS - 0 ))
	typeset -gr CHOICE_HEIGHT=12

	typeset -gr DIALOG_OK=0
	typeset -gr DIALOG_CANCEL=1
	
	typeset -gr DIALOG_TEMPFILE=$(mktemp 2>/dev/null) || DIALOG_TEMPFILE=/tmp/test$$
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
				--cancel-label "Exit" \
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
			mainmenu
            ;;
        2)
            search_platform
            ;;
        3)
            search_name
            ;;
        4)
            longdialoginfo "Miyoo Vimm's Lair Client - Version: 1.3"
			sleep 2
			mainmenu
            ;;
        *)
            longdialoginfo  "You quit Miyoo Vimm's Lair Client."
            sleep 1
            exit 0
            ;;
esac
}

search_vaultId() {
	if [ "$vaultId" = "" ]; then
		longdialoginfo "Please specify a valid Vault ID..."
		sleep 1
		mainmenu
	fi
	get_mediaId
	if [ "$mediaId" = "" ]; then
		longdialoginfo "Cannot find mediaId..."
		sleep 1
		mainmenu
	fi
	if [ "$mediaId" = "NO_SEL" ]; then
		mediaId=""
		mainmenu
	fi
	get_filePath
	get_gameName
	if [ "$gameName" = "" ]; then
		longdialoginfo "Cannot find game name..."
		sleep 1
		mainmenu
	fi
	get_imageName
	if [ "$imageFileName" = "" ]; then
		longdialoginfo "Cannot find game BoxArt..."
		sleep 1
	fi
	$($DIALOG --no-lines --yesno "Search result:\n\nFile:$gameName\nSize: $fileSize\nBoxArt: $imageFileName\nConsole: $console\nPath: $filePath\n\nPress Yes to confirm." 0 0 2>&1 >/dev/tty)
	if [ $? -ne 0 ]; then
		longdialoginfo "Download aborted..."
		sleep 1
		mainmenu
	fi
	download_game
	if [ "$res" = "" ]; then
		longdialoginfo "Game has been downloaded in: $filePath/$gameName"
		sleep 3
	fi
	mainmenu
}

get_mediaId() {
	url="https://vimm.net/vault/$vaultId"
	response=$(curl -s -k $url)
	if [ $? -ne 0 ]; then
		longdialoginfo "Error on HTTP connection..."
		sleep 1
		return
	fi
	local MEDIA = () ; unset MEDIA ; unset MEDIA
	echo "$response" | tr ';' '\n' | grep -i "var media = .*" >> allMedia
	while IFS= read -r line; do
		id=$(echo "$line" | grep -o '"ID":[0-9]*' | awk -F':' '{print $2}')
		goodTitle=$(echo "$line" | grep -o '"GoodTitle":"[^"]*"' | awk -F'"' '{print $4}')
		MEDIA+=(${id} ${goodTitle})
	done < allMedia
	fileSize=$(echo "$response" | sed -n 's/.*download_size">\([^"]*\).*/\1/p' | sed -n 's/<.*//p')
	size=${#MEDIA[@]}
	if [ $size -gt 2 ]; then
		$DIALOG --no-lines --title "Found more discs or versions: $(( size / 2 ))" --cancel-label "Back" --ok-label "Select" \
		--menu "Choose media to download:" 0 80 0 $MEDIA 2>$DIALOG_TEMPFILE
		ret=$?
		if [ $ret -ne 0 ]; then
			mediaId="NO_SEL"
			fileSize=""
			rm -rf allMedia
			return
		fi
		if [ $? -eq 0 ]; then
			mediaId=$(<$DIALOG_TEMPFILE)
			if [ "$mediaId" = "" ]; then
				longdialoginfo "You didn't choose any media ID, the default one will be selected."
				sleep 1
				mediaId=$(echo "$response" | sed -n 's/.*mediaId" value="\([^"]*\).*/\1/p')
				rm -rf allMedia
				return
			fi
			getFileSize $(grep $mediaId allMedia | sed -n 's/.*"Zipped":"\([^"]*\)".*/\1/p')
			if [ "$fileSize" = "" ]; then
				fileSize=$(echo "$response" | sed -n 's/.*download_size">\([^"]*\).*/\1/p' | sed -n 's/<.*//p')
			fi
			rm -rf allMedia
			return
		fi
		longdialoginfo "You didn't choose any media ID, the default one will be selected."
		sleep 1
	fi
	mediaId=$(echo "$response" | sed -n 's/.*mediaId" value="\([^"]*\).*/\1/p')
	rm -rf allMedia
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
		1 "Show all games"
        2 "Search by first chars"
        3 "Search by any substring"
        4 "Return"
    )

    local cmd=(
        $DIALOG --no-lines --title "Search by Platform" --cancel-label "Back" --menu "Choose an option" $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT 
    )
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	
	local GAMES=()

	case $choice in
		1)
			while IFS=';' read -r col1 col2 col3 col4; do
				if [[ "$col2" == "$console" ]]; then
					GAMES+=(${col3} $col1)
				fi
			done < "db/database.csv"
			;;
		2)
			letter=$($DIALOG --no-lines --inputbox "Enter the first letters or numbers and press OK" 0 0 2>&1 >/dev/tty)
			ret=$?
			if [ $ret -ne 0 ]; then
				browse_platform
			fi
			if [ $ret -eq 0 ]; then
				if [ "$letter" = "" ]; then
					longdialoginfo "Please enter at least a valid char..."
					sleep 1
					browse_platform
				fi
            	while IFS=';' read -r col1 col2 col3 col4; do
					if [[ "$col2" == "$console" && "$col1" == "$letter"* ]]; then
						GAMES+=(${col3} $col1)
					fi
				done < "db/database.csv"
			fi
			;;
		3)
			subs=$($DIALOG --no-lines --inputbox "Enter the substring and press OK" 0 0 2>&1 >/dev/tty)
			ret=$?
			if [ $ret -ne 0 ]; then
				browse_platform
			fi
			if [ $ret -eq 0 ]; then
				if [ "$subs" = "" ]; then
					longdialoginfo "Please enter a valid substring..."
					sleep 1
					browse_platform
				fi
            	while IFS=';' read -r col1 col2 col3 col4; do
					if [[ "$col2" == "$console" && "$col1" == *"$subs"* ]]; then
						GAMES+=(${col3} $col1)
					fi
				done < "db/database.csv"
			fi
			;;	
		*)
			search_platform
			;;
	esac
	
	size=${#GAMES[@]}
	if [ $size -eq 0 ]; then
		longdialoginfo "No result found..."
		sleep 1
		browse_platform
	fi
	$DIALOG --no-lines --title "Search results: $(( size / 2 ))" --cancel-label "Back" --ok-label "Select" \
		--menu "Choose game to download:" 0 80 0 $GAMES 2>$DIALOG_TEMPFILE
	if [ $? -eq 0 ]; then
		vaultId=$(<$DIALOG_TEMPFILE)
		search_vaultId
	fi
	browse_platform
}

search_platform() {
    local options=(
        1 "Atari 2600"
        2 "Atari 5200"
        3 "Atari 7800"
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
        $DIALOG --no-lines --title "Search by Platform" --cancel-label "Back" --menu "Select Platform Name" $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT 
    )
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	
	case $choice in
		1)
			console="Atari2600"
			;;
		2)
			console="Atari5200"
			;;
        3)
			console="Atari7800"
            ;;
        4)
			console="Lynx"
            ;;
        5)
			console="DS"
            ;;
        6)
			console="GB"
            ;;
        7)
			console="GBA"
            ;;
        8)
			console="GBC"
            ;;
        9)
			console="NES"
            ;;
        10)
			console="SNES"
            ;;
        11)
			console="VB"
            ;;
        12)
			console="32X"
            ;;
        13)
			console="GG"
            ;;
        14)
			console="SMS"
            ;;
        15)
			console="Genesis"
            ;;
        16)
			console="PS1"
            ;;
		*)
			console=""
			mainmenu
			;;
	esac
	browse_platform
}

search_name(){
	local options=(
		1 "Show all games"
        2 "Search by first chars"
        3 "Search by any substring"
        4 "Return"
    )

    local cmd=(
        $DIALOG --no-lines --title "Search by Name" --cancel-label "Back" --menu "Choose an option" $MAXHEIGHT $MAXWIDTH $CHOICE_HEIGHT 
    )
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
	
	local GAMES=()
		
	case $choice in
		1)
			while IFS=';' read -r col1 col2 col3 col4; do
				len=$(expr length "$col1 ($col2)")
				if [ "$len" -gt 40 ]; then
					con_len=$(expr length "$ ($col2)")
					max_len=$((40 - con_len))
					col1_cut=$(echo "$col1" | cut -c 1-$max_len)
				else
					col1_cut="$col1"
				fi
				GAMES+=(${col3} "$col1_cut ($col2)")
			done < "db/database.csv"
			;;
		2)
			letter=$($DIALOG --no-lines --inputbox "Enter the first letters or numbers and press OK" 0 0 2>&1 >/dev/tty)
			ret=$?
			if [ $ret -ne 0 ]; then
				search_name
			fi
			if [ $ret -eq 0 ]; then
				if [ "$letter" = "" ]; then
					longdialoginfo "Please enter at least a valid char..."
					sleep 1
					search_name
				fi
            	while IFS=';' read -r col1 col2 col3 col4; do
					if [[ "$col1" == "$letter"* ]]; then
						len=$(expr length "$col1 ($col2)")
						if [ "$len" -gt 40 ]; then
							con_len=$(expr length "$ ($col2)")
							max_len=$((40 - con_len))
							col1_cut=$(echo "$col1" | cut -c 1-$max_len)
						else
							col1_cut="$col1"
						fi
						GAMES+=(${col3} "$col1_cut ($col2)")
					fi
				done < "db/database.csv"
			fi
			;;
		3)
			subs=$($DIALOG --no-lines --inputbox "Enter the substring and press OK" 0 0 2>&1 >/dev/tty)
			ret=$?
			if [ $ret -ne 0 ]; then
				search_name
			fi
			if [ $ret -eq 0 ]; then
				if [ "$subs" = "" ]; then
					longdialoginfo "Please enter a valid substring..."
					sleep 1
					search_name
				fi
            	while IFS=';' read -r col1 col2 col3 col4; do
					if [[ "$col1" == *"$subs"* ]]; then
						len=$(expr length "$col1 ($col2)")
						if [ "$len" -gt 40 ]; then
							con_len=$(expr length "$ ($col2)")
							max_len=$((40 - con_len))
							col1_cut=$(echo "$col1" | cut -c 1-$max_len)

						else
							col1_cut="$col1"
						fi
						GAMES+=(${col3} "$col1_cut ($col2)")
					fi
				done < "db/database.csv"
			fi
			;;	
		*)
			mainmenu
			;;
	esac
	
	size=${#GAMES[@]}
	if [ $size -eq 0 ]; then
		longdialoginfo "No result found..."
		sleep 1
		search_name
	fi
	$DIALOG --no-lines --title "Search results: $(( size / 2 ))" --cancel-label "Back" --ok-label "Select" \
		--menu "Choose game to download:" 0 160 0 $GAMES 2>$DIALOG_TEMPFILE
	if [ $? -eq 0 ]; then
		vaultId=$(<$DIALOG_TEMPFILE)
		search_vaultId
	fi
	search_name
}

main