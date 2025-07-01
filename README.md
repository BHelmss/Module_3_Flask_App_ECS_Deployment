# Module_3_Flask_App_ECS_Deployment

## Topics Covered in Module 3
- Containers
- ECS, EKS, ECR
- Batch
- LightSail

## Prerequisites
- Docker
- Python Flask
- AWS CLI
  
## Project Description
I demonstrate how to contaizerize a Flask application locally and migrate it to cloud utilizing the Elastic Container Service(ECS) and EC2. The project includes the full workflow — from creating a Docker image and pushing it to Amazon ECR, to running the container on an ECS-managed EC2 instance.

## Steps

### 1. Create the Python Flask Application
- The followin code creates a very simple Flask app that displays a message when accessing the home page.
  
  ![image](https://github.com/user-attachments/assets/3a0557ae-e001-4f21-89d6-fde657bb50a9)

  
  ![image](https://github.com/user-attachments/assets/6608e367-8bea-4d95-9581-80e0221f492c)


### 2. Create a Docker File
- 2.1 Before creating the docker file, I make the requirements.txt document. This file tells docker what files (dependencies) are needed to run the application. The command 'pip freeze > requirements.txt' can be used to automatically output your current dependencies to the .txt file.

  ![image](https://github.com/user-attachments/assets/2df524e7-2d08-4ecf-b145-d51f99ca51de)

- 2.2 Next it is time to make the dockerfile. This file gives instructions on the actual contrusction of the container. It is a unique file that has no file extension.

### 3. Test the container locally
- 3.1 The first thing to do is to make sure you have docker installed. I didn't so I went to their official website and downloaded the appropriate version. This will also auto install WSL on your computer if you don't already have it. This is just a combatibility layer that lets you run a linux terminal on windows machine.
  
  ![image](https://github.com/user-attachments/assets/69d53b18-0aaf-46ef-8d45-ac7bd1bc22b4)

- 3.2 After docker was set up, I used the command 'docker build -t flask-ecs-app .' to build the container within the current directory. This command gives the container a name and tells it to use the current directory with the period at the end.
  
- 3.3 It is now time to actually run the container. I did this with 'docker run -p 5000:5000 flask-ecs-app'. However, it wouldnt let me connect over the url on my host machine. This is because back in the app.py flask file. I didn’t tell the app.run() funtion to accept connections from other interfaces. By default, this function only accepts the loopback address 127.0.0.1. This means that the container would only accept connections within itself and not from external sources like the url on my hostmachine. Making the below change fixed it.
```
Original:
if __name__ == '__main__':    
app.run(debug=True)

Fixed:
if __name__ == '__main__':    app.run(debug=True, host="0.0.0.0", port=5000)
```

- 3.4 Now that I had the container running I was able to connect to it via localhost. The flask app is running from within the docker container, the docker run -p 5000:5000 forwards from port 5000 on localhost to port 5000 within the container. Containers can be thought of as lightweight VM’s. So they have ports and network stacks just like a VM or physical machine. A container is essentially a mini version of the developer’s environment that takes all of the developer’s environment dependencies. You can then run the vm and utilize port forwarding to connect to the vm from your [localhost](http://localhost) machine. Migrating this to AWS essentially accomplishes the same thing. However, instead of it only being accessible by my host machine via [localhost](http://localhost) (or other devices on my private network if docker and firewall allow access on port 5000), it can be accessed anywhere in the world via either Fargate or EC2 server.

### 4. Push Container Image to ECR
- I first had to create a new ECR repository using the command 'aws ecr create-repository --repository-name flask-ecs-app'. The repo can now be viewed within the AWS console as well.
  
  ![image](https://github.com/user-attachments/assets/0001a3c7-1da0-4e8e-8449-d98ccc4628fe)

  ![image](https://github.com/user-attachments/assets/d5b8fa82-4b55-4300-adf6-545652d12045)

- Then I logged in with the following URI and default credentials used to verify connetion to docker.
  ```
  PS C:\Users\Brendan> aws ecr get-login-password | docker login --username AWS --password-stdin 940586025755.dkr.ecr.us-east-2.amazonaws.com/flask-ecs-app
  Login Succeeded
  ```
- I could then push the local docker image to the ECR repository with the following commands. The first gives the command a tag of latest and uses the same URI of the repo. The second pushes the image to the repo.

```
PS C:\Users\Brendan> docker tag flask-ecs-app:latest 940586025755.dkr.ecr.us-east-2.amazonaws.com/flask-ecs-app
PS C:\Users\Brendan> docker push 940586025755.dkr.ecr.us-east-2.amazonaws.com/flask-ecs-app
Using default tag: latest
The push refers to repository [940586025755.dkr.ecr.us-east-2.amazonaws.com/flask-ecs-app]
4147da3e4fab: Pushed
50a956a18493: Pushed
62dca1635333: Pushed
c14326ed6c85: Pushed
a668bf7387f5: Pushed
30d13a4d7c0e: Pushed
a358db7f3dc8: Pushed
dad67da3f26b: Pushed
4b03b4f4fa5c: Pushed
latest: digest: sha256:44d145d6334daff0df15fe87dffa34b25c1464aee0ea656dabefeedb37ab5129 size: 856
```

### 5. Deploy the image with ECS and EC2
- 5.1 First I created a new cluster on ECS. An ECS cluster is essentially a bunch of servers. ECS is a service designed to make container deployment much more mangeble. You can deploy your container image amonst many different servers without having to SSH into each and doing the same repetitive tasks such as installing docker.

  ![image](https://github.com/user-attachments/assets/9b04be4b-86bc-4da6-b01e-d139d8eae6f9)
  ![image](https://github.com/user-attachments/assets/ac7efb2d-b6b6-4a79-abef-1253d4fcb4da)

- 5.2 Then I created a new task definition. I gave the new task definition a name and gave it the launch type of EC2. I also scrolled down and filled the container settings for the container image resting in the ECR repo.

  ![image](https://github.com/user-attachments/assets/bcad9d4f-c5ec-4ad9-866d-6250cbf5c1b0)
  ![image](https://github.com/user-attachments/assets/ef0f9c20-f80e-4523-8423-46c8280574dd)

- 5.3 I made the task a service within the cluster. I opened the flask cluster and opened the services tab to create a new service. I selected the task we just created as the task family.

  ![image](https://github.com/user-attachments/assets/368aab0a-b3ed-44d4-a82f-1713065ad75b)

- 5.4 The last thing I did was navigate to the EC2 service and access the newly created EC2 instance. I went to its security group and added a new inbound rule to allow inbound traffic at port 5000. Now the container can be accessed.

  ![image](https://github.com/user-attachments/assets/13f9240c-332a-4985-900f-6c1765fe5295)

- 5.5 Then I cleaned up by backtracking and deleting all of the unneeded services.

## Conclusion
This project showcases the end-to-end process of deploying a containerized web application using AWS infrastructure. By leveraging Amazon ECS with EC2 and ECR, I gained hands-on experience with container orchestration, task definitions, service scaling, and networking on AWS. It reinforced my understanding of how cloud-native applications are packaged, deployed, and scaled in a production-like environment — skills directly aligned with AWS Cloud Practitioner certification topics and foundational DevOps practices.
