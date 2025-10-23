# Kong API Gateway

This project consists of two main modules:

- **kong**
- **terraform**

> **Note:** Details to be added.

---

## 🧩 Kong Module

This module includes configuration and setup scripts for Kong:

1. `kong.conf` – Kong configuration file.
2. `kong.yaml` – Plugin-related configurations.
3. `ec2-userdata` – One-time script to install Kong and deploy the code.

---

## ⚙️ Terraform Module

Follow these steps to deploy using Terraform:

1. Navigate to the `terraform` directory and run commands
   ```bash
   cd terraform
   #- Initialize Terraform:
   terraform init
   #Plan the deployment (enter your AWS key pair name when prompted):
   terraform plan
   #Apply the deployment (enter your AWS key pair name and confirm with "yes")
   terraform apply
   #To destroy the infrastructure:
   terraform destroy -auto-approve -var="key_pair_name=aws-keypair"
   #After deployment, outputs will include:
    Public URL , Admin URL
    ````

2. - In cmd run curl http://<ip-address>:8080/example  
   - this will give the error - "No API key found in request" which is expected

3. In cmd run http://<ip-address>/example -H "apikey: my-secret-key"
   this will route to actual url , and getting 503 as expected. or 200 OK
    ````
   <html>
   <head>
   <title>503 Service Temporarily Unavailable</title>
   </head>
   <body>
   <center>
   <h1>503 Service Temporarily Unavailable</h1>
   </center>
   </body>
   </html>
   ````
4. If we hit multiple time, rate limit error will be thrown as expected ( Configured in Kong)

   ```json
    {
    "message":"API rate limit exceeded",
    "request_id":"7ad6c960de28fa51877c9554868ef600"
    }
    ````

##keypair  aws-keypair
