# Use Azure Functions to build a RESTful API
![Azure Functions](images/AzureFunctionLogo.png)

Create an Azure Functions serverless API that returns a list of pets to be adopted. In this lab, you will learn how to create a basic REST API using Node.js Azure Functions and add dependencies from npm.

## Prerequisites

If you are **not** at an event, please see [REQUIREMENTS](REQUIREMENTS.md) to install the prerequisites for this lab.

## Create a Function App

Use the Azure Functions extension to create a new function app. 

* Open Visual Studio Code.

* In the Activity bar (on left side), select the Azure icon. 
> need screenshot
* Click the Create New Project button (the in the explorer).
![Azure Function Ext](images/create_function.png)

* Select *projects* folder.
> need Screenshot

Now the *Create new project* wizard appears.

- Select **JavaScript** for the language of the Function App

![Select JavaScript](images/select_javascript.png)

- Select **HTTP trigger** for the template

![Select HTTP trigger](images/select_HTTP_trigger.png)

- Replace the default function name **HttpTrigger** with **pets**
> need Screenshot

- Select **Anonymous** for the *Authorization level*
![Choose Ananymous](images/choose_Anonymous.png)

* Select **Open in current window**


The HTTP Trigger function just created is opened in the editor window.
> Need Screenshot

## Run the Function locally

Using a template to create the function, creates a working Http Trigger function we can test locally.<br>
Let's try it now:

* **Start Debugging** - In the Menu bar, select **Start Debugging** from the *Debug* menu. Or press **Fn+F5** 

A Terminal opens with the debug output. <br>
Debug automatically excutes *run npm install*, to install any depencies, and starts the Azure Functions host. 

Once the host is started, the URL appears.

* **Test URL** - Hold **Crtl** while click the URL or type `http://localhost:7071/api/pets` in a browser. 
You should see a message that says “Please pass a name on the query string or in the request body”. 

* Add a query parameter, `name`, to the URL: `?name=OSCON`. 
`http://localhost:7071/api/pets?name=OSCON`
Press **Enter** and now the page should say: "Hello OSCON"
> need screenshot

* **Stop Debug** - In the Menu bar, select **Stop Debugging** from the Debug menu. Or press **Shift+Fn+F5** 

## Finding pets for adoption

Now we'll update the function to pull a list of pets that are available for adoption. 
> Should expand to explain where the list is coming from.

* Open a **Terminal Window** from the *Terminal* menu or **Ctrl+Shift+`** 

* In the Terminal, install the `pet` module from npm by running `npm install @frontendmasters/pet --save`. 

* **Update function code** - Replace the default code in the index.js with:

```js
const pet = require("@frontendmasters/pet");

module.exports = async function(context, req) {
  const response = await pet.animals();

  if (!response.animals)
    return (context.res = {
      status: 500,
      body: response.message
    });

  context.res = {
    body: response.animals
  };
};
```
Now we're ready to test the new code:

* **Start Debugging** - In the Menu bar, select **Start Debugging** from the *Debug* menu. Or press **Fn+F5** 

> Note: if the module fails to make the request to get available animals, the endpoint needs to handle that error and send an appropriate status code and response.

> JJ - Are we saying the user needs to handle the error response? It fails the first time, so the user needs to run Debug again to start up?

* Start Debug again and load the URL `http://localhost:7071/api/pets`. <br>
This time, an JSON array of pets along with links to photos and more information for each.

At this point, you can hook a front-end up to you API and start helping lovely animals find happy homes!

* **Stop Debug** - In the Menu bar, select **Stop Debugging** from the Debug menu. Or press **Shift+Fn+F5** 

## Next steps

- [Sample app with an Angular front end connected to Azure Functions](https://github.com/fiveisprime/apm)
