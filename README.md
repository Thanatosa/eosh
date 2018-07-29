# eosh
A secure, local, offline, hardware wallet solution for eosio blockchains.<br>

<b>Features</b>
* Free
* Minimal dependencies
   * Ubuntu installation and repository
  * eosio code
* Disabled attack vectors
  * Encrypted installation
  * No network connections
  * No swap disk
  * No process trace
  * Erased RAM
* Written entirely in bash
  * Ubuntu native command line script
  * Required for interaction with eosio code
  * Open source code
* Local blockchain 
  * Test transactions first
  * Test smart contracts
* QR code transaction
  * Generated offline and locally on dedicated device
  * Transmitted through webpage with no external source
  * https straight to a choice of block producer endpoints
* Fast access to new features
  * Updated system contracts
  * Any smart contract
* Layered use cases
  * Interact via eoshGUI
  * Interact with eosh scripts
  * Interact with eosio code directly
  * Use eosh code as example code

<b>Required Hardware</b><br>
64-bit processor<br>
6 GB of RAM (might work with less)<br>
A dedicated storage device, flash drive, HDD, SSD. At least 64 GB. Recommended 128 GB.<br>
DVD Writer<br>
Writable DVD<br>
Any smartphone with camera<br>

<b>Instructions</b><br>
Download Ubuntu 18.04 iso and burn to disk. http://releases.ubuntu.com/18.04/. The 64-bit PC (AMD64) desktop image, is the image for AMD and Intel processors.<br>
Install from disk onto storage device. 18.04 normal installation.<br>
Use an encrypted installation with strong password to prevent tampering.<br>
Let the Ubuntu updater run.<br>
Open a command line terminal, ctrl+alt+t<br>
```
       sudo apt install git
       cd ~/
       git clone https://github.com/thanatosa/eosh
       chmod +x ~/eosh/install/Install.sh
       ~/eosh/install/Install.sh
```
This will take a while, about 75 mins and you might be asked to input password a few times<br>
Double click desktop icon or click show applications icon in the bottom left and type eoshGUI and run the GUI<br>
from the function menu select eosh: Quick Start Walkthrough<br>
<br>
<b>Broadcast transaction page</b><br>
https://thanatosa.github.io/eosh/<br>
