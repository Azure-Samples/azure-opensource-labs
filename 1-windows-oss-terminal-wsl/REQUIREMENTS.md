# REQUIREMENTS

- Windows Insider build 18917 or higher
- Windows Terminal https://github.com/microsoft/terminal
- git https://git-scm.com/downloads
- VS Code https://github.com/microsoft/vscode
- WSL https://aka.ms/wsl2
- Ubuntu 18.04 for WSL in the [Microsoft Store](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q)
  - for the lab use username "oscon" and password "portland"
- NodeJS and NPM: sudo apt install npm -y
- In Windows install fonts using Powershell:<br/>
  - git clone https://github.com/powerline/fonts.git
  - run install.ps1 pro*
- In Ubuntu install the powerline shell:<br/>
  - sudo apt install python3 pip 
  - pip install powerline-shell

### Setup
- git clone https://github.com/mscraigloewen/nodejs-shopping-cart into c:\projects

### Cleanup
- delete c:\projects\nodejs-shopping-cart\node-modules
- close all running Terminal or Code windows
- delete terminal profile file: 
  - ```C:\Users\[USERNAME]\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\profiles.json```
