# Udagram Image Filtering Application microservices project

Udagram is a simple cloud application developed alongside the Udacity Cloud Developer Nanodegree. It allows users to register and log into a web client, post photos to the feed, and process photos using an image filtering microservice.

This project demonstrates microservices architecture with A/B deployment and rolling update using Docker, Kubernetes (AWS EKS), GitHub Actions, and Nginx as a reverse proxy.

## Table of Contents

- [Udagram Image Filtering Application microservices project](#udagram-image-filtering-application-microservices-project)
	- [Table of Contents](#table-of-contents)
	- [Introduction](#introduction)
	- [Prerequisites](#prerequisites)
	- [Setup](#setup)
			- [Environment Script](#environment-script)
		- [Database](#database)
		- [S3](#s3)
		- [Microservices Backend (RESTful API - Node-Express application)](#microservices-backend-restful-api---node-express-application)
		- [Frontend (Angular web application built with Ionic Framework)](#frontend-angular-web-application-built-with-ionic-framework)
		- [Nginx Reverse Proxy](#nginx-reverse-proxy)
	- [Deployment](#deployment)
		- [AWS EKS](#aws-eks)
	- [GitHub Actions Workflow](#github-actions-workflow)
	- [Monitor with CloudWatch Container Insights](#monitor-with-cloudwatch-container-insights)
	- [File Structure](#file-structure)

## Introduction

This project showcases a microservices architecture with two backend services, two versions of the frontend for Kubernetes A/B deployment, and an Nginx reverse proxy to manage routing. The setup utilizes Docker for containerization, AWS EKS for Kubernetes orchestration, and GitHub Actions for automated updates and deployments.

## Prerequisites

Before you begin, ensure you have the following prerequisites installed:

- Docker
- Kubernetes CLI (`kubectl`)
- AWS CLI
- GitHub account with necessary repository access
- Node v14.21.3 (npm v6.14.18)

## Setup

#### Environment Script
Prepare a `set_env.sh` to help you to configure these variables on your local development environment.
```
export POSTGRES_USERNAME=username
export POSTGRES_PASSWORD=pw
export POSTGRES_HOST=postgres.xxxxxx.<region>.rds.amazonaws.com
export POSTGRES_DB=postgres
export AWS_BUCKET=s3 bucket name
export AWS_REGION=region
export AWS_PROFILE=default
export JWT_SECRET=testing
export URL=http://localhost:8100
```
Afterwards, please prevent the file from being included in your solution by adding the file to our `.gitignore` file.

### Database
Create a PostgreSQL database either locally or on AWS RDS. The database is used to store the application's metadata.

* We will need to use password authentication for this project. This means that a username and password is needed to authenticate and access the database.
* The port number will need to be set as `5432`. This is the typical port that is used by PostgreSQL so it is usually set to this port by default.

Once your database is set up, set the config values for environment variables prefixed with `POSTGRES_` in `set_env.sh`.
* If you set up a local database, your `POSTGRES_HOST` is most likely `localhost`
* If you set up an RDS database, your `POSTGRES_HOST` is most likely in the following format: `***.****.us-west-1.rds.amazonaws.com`. You can find this value in the AWS console's RDS dashboard.

* you can run `source set_env.sh` to configure the env variable in local terminal.


### S3
Create an AWS S3 bucket. The S3 bucket is used to store images that are displayed in Udagram.

Set the config values for environment variables prefixed with `AWS_` in `set_env.sh`.

AWS S3 bucket name should be universally unique.

### Microservices Backend (RESTful API - Node-Express application)

1. Go to each microservices backend repository.
```bash
cd udagram-api-feed
cd udagram-api-user
```

2. Build and run the Docker images for each microservice.
```bash
docker build -t udagram-api-feed:v1 .
docker build -t udagram-api-user:v1 .
```

Launch the backend API locally:

The API is the application's interface to S3 and the database.

* To download all the package dependencies, run the command from each directory:
    ```bash
    npm install .
    ```
* To run the application locally, run:
    ```bash
    npm run dev
    ```
* You can visit `http://localhost:8080/api/v0/feed`, `http://localhost:8080/api/v0/user` in your web browser to verify that the application is running.

### Frontend (Angular web application built with Ionic Framework)

1. Go to each frontend repository.
```bash
cd udagram-frontend-a
cd udagram-frontend-b
```

2. Build and run the Docker images for each version.
```bash
docker build -t udagram-frontend-a:v1 .
docker build -t udagram-frontend-b:v1 .
```
3. Configure environment variables in `./src/environments`.

Launch the frontend app locally:

* To download all the package dependencies, run the command from the directory:
    ```bash
    npm install
    ```
* Install Ionic Framework's Command Line tools for us to build and run the application:
    ```bash
    npm install -g ionic
    ```
* Prepare your application by compiling them into static files.
    ```bash
    ionic build
    ```
* Run the application locally using files created from the `ionic build` command.
    ```bash
    ionic serve
    ```
* You can visit `http://localhost:8100` in your web browser to verify that the application is running. You should see a web interface.

### Nginx Reverse Proxy

1. Go to udagram-reverseproxy repository.
```bash
cd udagram-reverseproxy
```

2. Build and run the Nginx Docker image.
```bash
docker build -t nginx-reverse-proxy .
```

## Deployment

### AWS EKS
The steps are for the initial manual deployment.
For the future deployments, it uses github actions.

1. Create an AWS EKS cluster.
```bash
aws eks create-cluster --name my-cluster --role-arn eks-service-role-arn --resources-vpc-config subnetIds=subnet-ids,securityGroupIds=security-group-ids
```

2. Configure `kubectl` to use the new EKS cluster.
```bash
aws eks --region region update-kubeconfig --name my-cluster
```

3. Update secrets
```bash
aws-secret.yaml
env-secret.yaml
env-configmap.yaml
```

4. Deploy to the EKS cluster.
```
cd k8s
./deploy.sh
```

5. Monitor the deployment using `kubectl get pods`, `kubectl get services`, etc.

6. Change `apiHost:` to load balancer service URL and re-deploy two frontend applications.

7. Access frontend with reverse proxy load balancer service URL.

## GitHub Actions Workflow

The project is configured with GitHub Actions for automated updates and deployments. The workflow can be found in the `.github/workflows` directory. Ensure that GitHub Secrets for AWS credentials are set in the repository.

## Monitor with CloudWatch Container Insights
1. Enable CloudWatchAgentServer Policy for the worker node IAM Role
2. Execute command
```bash
ClusterName='<my-cluster-name>'
RegionName='<my-cluster-region>'
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f -
```

![Container Insights](https://github.com/loxinchi/capstone-microservice/assets/76967954/f3f5e689-8a21-428a-8e4f-21cffa9efdd6)

## File Structure

- **udagram-api-feed**: Contains microservices backend source code.
- **udagram-api-user**: Contains microservices backend source code.
- **udagram-frontend-***: Contains frontend source code.
- **nginx-reverse-proxy**: Contains Nginx reverse proxy configuration.
- **.github/workflows**: GitHub Actions workflow files.
- **k8s**: Contains Kubernetes deployment and service files and secrets configurations.

<!-- ## License

This project is licensed under the (LICENSE). -->
