# Windows for Open Source Developers

This project walks you through setting up and customizing a Windows PC for Open Source development.  We'll introduce you to Windows Terminal and WSL. At the end of this lab you'll use VS Code to debug a NodeJS project running in WSL. 

## Getting Started


### Prerequisites

- Windows Insider build 18917 or higher
- Windows Terminal https://github.com/microsoft/terminal
- VS Code https://github.com/microsoft/vscode
- WSL https://aka.ms/wsl2
- Ubuntu 18.04 for WSL in the [Microsoft Store](https://www.microsoft.com/en-us/p/ubuntu-1804-lts/9n9tngvndl3q)

### Installation

- run LabClean.ps 
- clone NodeJS Sample project

### Quickstart
(Add steps to get up and running quickly)

1. git clone [repository clone url]
2. cd [respository name]
3. ...

### Configure the Terminal
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
            "padding" : "0, 0, 0, 0",
            "snapOnInput" : true,
            "useAcrylic" : false
        },`

Now open the Terminal Menu and you'll see a new entry 'My OSCON Profile".  Select this profile and a new tab opens with this profile.  Give it a try.  Next we'll customize this.

#### Customize the Terminal Profile


### Run a Node Project in WSL
In the Terminal using your OSCON profile, navigate to the NodeJS sample in `c:\\projects\NodeSample`
1. run `npm install`
2. run `npm .`
3. Use a web browser to open `localhost:3000` to see the site is working.  This is the Linux version of NodeJS running locally on Windows. 

### Debug a Node Project with VS Code
1. type `code .` to open this project in VS Code
2. This opens VS Code on Windows with a feature to debug the NodeJS project running in WSL
3. In VS Code run the debugger
4. Open a browser to localhost:3000 and view the site is running 


## Demo


## Resources

- https://aka.ms/learnwsl
