# Create a Sandbox SQL Server 2019 Linux Container with AdventureWorks 2017 Demo Data 

This lab example allows you to create and deploy a containerised SQL Server 2019 instance containing the AdverntureWorks 2017 sample data.
The built-in configuration and runtime scripts ensure that users are not allowed to change the SA password and the data is cleaned up each time the container restarts.

## Requirements

You need to be able to run Docker on your local environment.

## Steps

1. Build the docker image from the Dockerfile and resources in this directory by running the following docker command from console
```
docker build -t sqlsrv2019sandox .
```
1. Run the container
```
docker run -p 1433:1433 -e PORT=1433 
```
1. You can override the default SA password specified in the Dockerfile by replacing the environment variable "SA_PASSWORD" in the Dockerfile
1. You can now connect to the SQL Server container on the localhost
