# REQUIREMENTS

- Windows Insider build 18917 or higher
- Windows Terminal https://github.com/microsoft/terminal
- VS Code https://github.com/microsoft/vscode
- WSL https://aka.ms/wsl2
- Ubuntu 18.04 for WSL in the [Microsoft Store](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q)
  - for the lab use username "oscon" and password "portland"
- python and python-setuptools in Windows
- install powerline shell and fonts using Powershell:<br/>
git clone https://github.com/powerline/fonts.git
<br/>cd fonts<br/>./install.ps1 pro*

### Setup
- clone https://github.com/mscraigloewen/nodejs-shopping-cart into c:\projects

### Cleanup
- delete c:\projects\nodejs-shopping-cart\node-modules
- close all running Terminal or Code windows
- delete terminal profile file: 
  - ```C:\Users\[USERNAME]\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\RoamingState\profiles.json```
