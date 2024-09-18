# vimm-client-miyoo

A simple Vimm's Lair client for Miyoo Mini Plus

## Version

This application is currently at version 1.7

---

## Overview

This project is in its early stages and can have probably bugs. This project is not intended to help any kind of piracy, it's just a case of study.

- Discord Contact: @vitty85

---

## Requirements

- Packaged for Onion App (Porting to other UIs is welcome)
- Latest version of Onion (https://github.com/OnionUI/Onion/releases/latest)
- Recent firmware (You need at least firmware version 20220419****)

---

## How to Install Vimm's Lair Client on your Miyoo MMP

Just copy the MiyooVimmClient folder into `/mnt/SDCARD/App/` on your MMP and then run it from Miyoo Apps menu.

### Screenshots

   ![script_000](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/c47fd62d-9284-44e8-a3f0-58d30be6207a)
   ![script_001](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/e4f2e6b9-aa50-4d65-9beb-b7a46d2cf790)
   ![script_002](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/5d01b182-19dc-44c1-9053-be37abe2e310)
   ![script_003](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/b54838d8-b597-40a8-88cc-648f760718ea)
   ![script_005](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/c14f57df-9fb7-4918-befa-398678f384c0)
   ![script_007](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/2cabd0a2-70e3-4a86-98c0-aa33d69acc79)
   ![script_008](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/0b643eaa-274d-42aa-bfff-a35862134278)
   ![Commander_Italic_001](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/05cb8009-7af7-4ab1-bcd1-5345af7e39fc)
   ![script_006](https://github.com/Vitty85/vimm-client-miyoo/assets/53129080/c3d32f55-362b-4c29-a1b1-d38579515fb9)

---

## Credits

- XK for inspiration taken from BetterWifi App
  - [BetterWiFi Repository](https://github.com/XK9274/better-wifi-miyoo)
- Curo19 and DanCousins for the inspiration i took from their projects
  - [romDownloader Repository](https://github.com/Curo19/romDownloader)
  - [vdl Repository](https://github.com/DanCousins/vdl)
- [Vimm's Lair website](https://vimm.net)
- [Libretro GitHub Repository](https://github.com/libretro-thumbnails)

## Third party binaries:

- zsh w/ regex https://github.com/zsh-users/zsh
- dialog https://invisible-island.net/dialog/

---

## Frequently Asked Questions (FAQ)

### Is this App legit?
- It depends on how you are going to use it!! Basically this client is like a Browser pointed to a specific Web page.

### Is the author of this app involved directly with Vimm's Lair somehow?
- Absolutely not, all the games are hosted on Vimm's Lair website and i'm not connected to them in any way.

---

## Changelog

### v1.7
   - Fixed download link from Vimm's Lair portal

### v1.6
   - Updated database
   - Fixed download link from Vimm's Lair portal

### v1.5
   - Updated database
   - Fixed the selection of specific media ID for multi disc / version games
   - Fixed download size calculation on multi disc / version game

### v1.4
   - Updated database
   - Added Nintendo64, Sega MegaCD and Sega Saturn Platforms in search menu

### v1.3
   - Fixed Atari7800 Platform name in menu
   - Fixed database for missing Atari5200 and Virtual Boy games (it was always showing no result on search)

### v1.2
   - Improved navigation and item selection on menu
   - Allow user to display more than 20 results on a single search
   - Addded a show all games option in both search by Name and search by Platform menu
   - Fixed download size calculation on multi disc / version game

### v1.1
   - Added about menu with app version
   - Allow user to select a specific media ID for multi disc / version games

### v1.0
   - First release of app
   - Allow user to search game by Vault ID (from Vimm's Lair database)
   - Allow user to search game by Platform (there are 16 available and compatible with OnionOS)
   - Allow user to search game by Name (it's possible to specify the starting chars or a contained substring)
   - Any search can return maximum 20 hits (so try to be use specific keyword to reduce the matches)
   - Allow user to uncompress both zip and 7z archives (when you choose to uncompress the app will create a folder with same name of downloaded game and remove the zipped file)
   - Allow user to download both game and box Art and place them into correct MMP folder according to Platform (it follows the Emu mapping of OnionOS)

---
