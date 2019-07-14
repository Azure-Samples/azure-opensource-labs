# REQUIREMENTS

- Windows Insider build 18917 or higher
- Windows Terminal https://github.com/microsoft/terminal
- git https://git-scm.com/downloads
- VS Code https://github.com/microsoft/vscode
- WSL https://aka.ms/wsl2
  - Open optional windows features and select `WSL` and `Virtual Machine Platform`.  NOTE: This will require a system reboot
- Ubuntu 18.04 for WSL in the [Microsoft Store](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q)
  - for the lab set the username to "oscon" and password "portland"
  - migrate this distro to WSL 2 from a cmd window by runnig  `wsl --set-version Ubuntu-18.04 2` 
- NodeJS and NPM: sudo apt install npm -y
- In Windows install fonts using Powershell:<br/>
  - git clone https://github.com/powerline/fonts.git
  - run install.ps1 pro*
- In Ubuntu install the powerline shell:<br/>
  - sudo apt install python3 pip 
  - pip install powerline-shell

### Setup
- From the Ubuntu shell create a projects directory in your HOME (~\projects) and in that directory run `git clone https://github.com/mscraigloewen/nodejs-shopping-cart` 

### Cleanup
- delete ~\projects\nodejs-shopping-cart\node_modules
- close all running Terminal or Code windows
- delete terminal profile file: 
  - ```C:\Users\[USERNAME]\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\profiles.json```
