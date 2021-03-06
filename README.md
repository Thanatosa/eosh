
<dl><img src="https://github.com/Thanatosa/eosh/blob/master/icons/256x256.png" width=64 height=64 /></dl>

# eosh
#### A secure, local, offline, hardware wallet solution for eosio blockchains.
---

#### Features
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

#### Required Hardware
* 64-bit processor.
* 6 GB of RAM (might work with less).
* A dedicated storage device, flash drive, HDD, SSD.
   * 64 GB minimum.
   * 128 GB recommended.
* DVD Writer.
* Writable DVD.
* Any smartphone with camera.

#### Instructions
* Download Ubuntu 18.04
   * http://releases.ubuntu.com/18.04/.
   * The 64-bit PC (AMD64) desktop image, is the image for AMD and Intel processors.
   * Burn iso image to disk.
* Install from disk onto storage device.
   * 18.04 normal installation.
   * Use an encrypted installation with strong password.
* Let the Ubuntu updater run.
* Open a command line terminal
   * ctrl+alt+t
   * Type the following commands:
```
       sudo apt install git
       cd ~/
       git clone https://github.com/thanatosa/eosh
       chmod +x ~/eosh/install/Install.sh
       ~/eosh/install/Install.sh
```
   * This will take about 75 mins.
   * You might be asked to input your password a few times.
   * Double click the desktop icon or click show applications icon in the bottom left and type eoshGUI to run the GUI.
   * From the function menu select eosh: Quick Start Walkthrough.
   
#### Broadcast transaction to mainnet</b>
* for EOS mainnet, Via smartphone visit https://thanatosa.github.io/eosh/
* for Telos mainnet, Via smartphone visit https://thanatosa.github.io/eosh/telosbroadcast.html
* for Jungle testnext, via smartphone visit https://thanatosa.github.io/eosh/jungletestnetbroadcast.html
* Get reference block data from a block producer endpoint of your choice.
* Use any QR code reader to scan the given QR code from your offline installation.
* Copy and paste text.
* Broadcast securely using https directy to a block producer endpoint of your choice.

#### Telegram Group
* t.me/eoshwallet
