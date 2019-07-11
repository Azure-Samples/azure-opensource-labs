# Windows for Open Source Developers

This project walks you through setting up and customizing a Windows PC for Open Source development.  We'll introduce you to Windows Terminal and the Windows Subsystem for Linux (WSL) 2. At the end of this lab you'll use VS Code to debug a NodeJS project running in WSL. 

## Getting Started

### Prerequisites

If you are **not** at an event, please see [REQUIREMENTS](REQUIREMENTS.md) to install the pre-requisites for this lab.

### Configure the Terminal

#### PROFILES

Open Windows Terminal and press `Ctrl + ,` to edit the settings file (you can alternatively use the Terminal menu and select "settings")

In the list of profiles insert this profile: <br/> 
`        {
            "guid" : "{c6eaf9f4-56a1-5fdc-b5cf-066e8a4b1e40}",
            "acrylicOpacity" : 0.5,
            "closeOnExit" : true,
            "colorScheme" : "Campbell",
            "commandline" : "wsl.exe -d Ubuntu-18.04",
            "cursorColor" : "#FFFFFF",
            "cursorShape" : "bar",
            "fontFace" : "Consolas",
            "fontSize" : 12,
            "historySize" : 9001,
            "icon" : "ms-appx:///ProfileIcons/{9acb9455-ca41-5af7-950f-6bca1bc9722f}.png",
            "name" : "My OSCON Profile",
            "padding" : "4, 2, 4, 2",
            "snapOnInput" : true,
            "useAcrylic" : false
        },`

Now open the Terminal Menu and you'll see a new entry 'My OSCON Profile".  Select this profile and a new tab opens with this profile.  Give it a try.  Next we'll customize this.

This profile will open an Ubuntu 18 bash shell. 

Feel free to change any of the settings and the Terminal will automatically reload with your changes as you go.

For cursorShape try "vintage"

#### POWERLINE FONT
Next we're going to install PowerLine fonts in Windows using PowerShell: 
1. git clone https://github.com/powerline/fonts.git
2. cd fonts
3. ./install.ps1

Next change your terminal profile to use one of the Powerline fonts:

`"fontFace" : "ProFont for Powerline",`


#### POWERLINE SHELL
With the fonts installed, you can install the PowerLine shell in Ubuntu by addign the following to your .bashrc.  Open ~\\.bashrc and add the following.

`function _update_ps1() {
    PS1=$(powerline-shell $?)
}`

`if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi`

NOTE: You can use Windows File Explorer to open this file by navigating to
<br/>
`\\wsl$\Ubuntu-18.04\home\USERNAME` and opening .bashrc in any Windows editor like Notepad.

#### TMUX
To have multiple panes within our shell use Tmux.  Here's how:
1. Run `sudo apt install tmux -y`
2. Open a new tmux session by typing `tmux` and pressing enter
3. Add panes using the following:
- Press **CTRL+B** and then **"** to split the screen vertically
- Press **CTRL+B** and then **%** to split the screen horizontally
- Use **CTRL+B** and then the arrow keys to navigate between the screens
- Use whatever mix and match of cool apps you'd like here. I recommend using `htop` in the top Window, `cmatrix` on the bottom left and `cacafire`
- To quit a window press **CTRL+B** and then **x** and then press **y** to accept. 
- Quit all windows to exit the tmux session.

### Run a Node Project in WSL
In the Terminal using your OSCON profile, navigate to
 `c:\\projects\`
1. run `git clone https://github.com/johnpapa/node-hello`
2. run `cd node-hello`
3. run `npm install`
2. run `npm start`
3. Use a web browser to open `localhost:3000` to see the site is working.  This is the Linux version of NodeJS running locally on Windows via WSL. 

#### STARTING DIRECTORY
You can add the following line to your Terminal profile, so now it will open to your project folder:<br/>
`"startingDirectory" : "C:\projects\node-hello"`

### Debug a Node Project with VS Code
1. type `code .` to open this project in VS Code
2. This opens VS Code on Windows with a feature to debug the NodeJS project running in WSL
3. In VS Code run the debugger

## Demo
## Resources
- https://aka.ms/learnwsl
