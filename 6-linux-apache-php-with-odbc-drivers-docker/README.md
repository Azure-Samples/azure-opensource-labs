# Azure Custom Web App with Ubuntu 18.04, Apache 2, PHP7.2 and SSH with ODBC Drivers

When developing PHP applications with Microsoft SQL Server or Azure SQL DB services, ODBC drivers and SQLSRV extension are required.
This lab allows you to create a docker container based on the Ubuntu image along with Apache 2 and PHP 7 for deployment on Azure as a custom Web App.

Custom web apps however do not support SSH on Azure through the Azure Portal out of the box.
The example here adds the necessary configuration to Dockerfile that enables this functionality.

## Requirements

You need to be able to run Docker on your local environment and have access to a container registry. Docker Hub is used in this lab example.
You should also have access to an Azure subscription and have the requisite permissions to be able to create new resources.

Build and run scripts have been included in here (build.sh and run.sh) but will require a linux environment to run.

## Steps

1. Build the docker image from the Dockerfile and resources in this directory by running the following docker command from console
```
docker build -t azlampodbc .
```
1. Push the docker image to your container repository you may need to replace repository/azlampodbc to the path for your repository
```
docker push repository/azlampodbc
```
1. From the Azure Portal (https://portal.azure.com), create a new Web App and fill in the required parameters. 
    * Specify the "Publish" parameter as "Docker Image"
    * Select the appropriate Sku and Size for the Web App (The F1 tier is free for 60 minutes a day)
1. In the next tab, "Docker", specify the following values (you may use the examples below from the official Azure lampodbc image):
    * Options: Single Container
    * Image Source: Docker Hub (or your own container registry)
    * Access Type: Public (or Private depending on your repository)
    * Image and Tag: chubbycat/lampodbc:development-with_msft-az-php-sdk_latest
    * Startup Commnand: Leave this blank
1. Specify all other parameters and create the Web App
1. Once the web app has been deployed, head over to the resource and then to the Container Settings blade. You should be able to check the status of the deployment under the Logs section
    * The logs will indicate pull operations from the container registry and for the various layers in the container
    * Subsequently the various layers will be extracted 
    * Once completed, the logs will indicate that the site has been initialised and ready to serve requests
1. Head over to the URL indicated in the Overview blade to check that the web server is running. You should see the default Apache2 Ubuntu landing page.
