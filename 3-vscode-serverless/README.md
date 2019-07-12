# Use Azure Functions to build a RESTful API

Create an Azure Functions serverless API that returns a list of pets to be adopted. In this lab, you will learn how to create a basic REST API using Node.js Azure Functions and add dependencies from npm.

## Prerequisites

If you are **not** at an event, please see [REQUIREMENTS](REQUIREMENTS.md) to install the prerequisites for this lab.

## Create a Function App

Use the Azure Functions extension to create a new function app. Start by navigating to the Azure view in Visual Studio Code (the on the left-hand side), then click the Create New Project button (the in the explorer).
Choose the current workspace to create the Function App then choose the following options

- Choose JavaScript when prompted for the language of the Function App
- Choose HTTP Trigger when prompted to create the first Azure Function in the Function App
- Name the Function "pets"
- Choose Anonymous for the authorization level

The Function App is created and the HTTP Function you just created is opened in the editor windows of Visual Studio Code.

## Test the default Function in the browser

The Azure Functions extension created all required configuration for running your Function App locally. Start the Function App by hitting F5 or by choosing Debug, Start Debugging from the menu in Visual Studio Code.
Visual Studio Code will automatically run npm install then start the Azure Functions host and make the Function available on port 7071. You’ll know the app started correctly when you see the following.

Hold the Control key and click the URL or open the browser and navigate to `http://localhost:7071/api/pets`. You should see a message that says “Please pass a name on the query string or in the request body,” add the `name` query parameter by updating the URL to include `?name=OSCON`. You will see "Hello OSCON!"

Stop the app and disconnect the debugger by clicking the button.

## Finding pets for adoption

Update the pets Function to get a list of pets that are available for adoption. First, install the `pet` module from npm by running `npm install @frontendmasters/pet --save`. Import the module fetch animals that are available for adoption using the `animals` method and return the result.

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

> Note: if the module fails to make the request to get available animals, the endpoint needs to handle that error and send an appropriate status code and response.

Launch the app using the debugger again (F5 or Debug, Start Debugging from the menu) and access the updated API endpoint on `http://localhost:7071/api/pets`. This time, you'll see an array of pets along with links to photos and more information for each.

At this point, you can hook a front-end up to you API and start helping lovely animals find happy homes!

## Next steps

- [Sample app with an Angular front end connected to Azure Functions](https://github.com/fiveisprime/apm)
