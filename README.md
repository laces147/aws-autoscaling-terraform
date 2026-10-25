# AWS Auto Scaling Infrastructure with Terraform

This project demonstrates how to build a scalable and highly available web infrastructure on AWS using Terraform.

The infrastructure deploys an internet-facing Application Load Balancer across two public subnets and an Auto Scaling Group of EC2 instances across two private subnets in separate Availability Zones.

The Auto Scaling Group uses a target tracking policy based on average CPU utilization. During testing, CPU load was generated on the EC2 instances to observe the environment automatically scale from 1 instance to 2 and then to 4 instances as demand increased.

## Project Objectives

The objectives of this project were to:

- Build AWS infrastructure using Infrastructure as Code (IaC) with Terraform.
- Deploy resources across multiple Availability Zones.
- Place application servers in private subnets rather than exposing them directly to the internet.
- Distribute incoming HTTP traffic using an Application Load Balancer.
- Automatically increase or decrease EC2 capacity based on CPU utilization.
- Use IAM roles and AWS Systems Manager for instance management.
- Test the Auto Scaling configuration under simulated CPU load.
- Understand how AWS networking, load balancing, monitoring, and Auto Scaling work together.

## Architecture

The infrastructure uses a multi-AZ VPC design with separate public and private subnets.

### Traffic Flow

Internet
   |
   v
Application Load Balancer
   |
   v
Target Group
   |
   v
Auto Scaling Group
   |
   +-------------------+
   |                   |
   v                   v
EC2 Instance       EC2 Instance
Private Subnet A   Private Subnet B
   |                   |
   +---------+---------+
             |
             v
        NAT Gateway
             |
             v
      Internet Gateway

### Architecture Components

- **VPC** — Provides an isolated network for the infrastructure.
- **Public Subnets** — Host the Application Load Balancer and NAT Gateway.
- **Private Subnets** — Host the EC2 instances managed by the Auto Scaling Group.
- **Internet Gateway** — Provides internet connectivity for resources in the public subnets.
- **NAT Gateway** — Allows instances in the private subnets to initiate outbound internet connections without being directly accessible from the internet.
- **Application Load Balancer (ALB)** — Receives HTTP traffic and distributes requests to healthy EC2 instances.
- **Target Group** — Registers the EC2 instances and performs health checks before the ALB sends traffic to them.
- **Launch Template** — Defines how new EC2 instances are created, including the AMI, instance type, security group, IAM instance profile, and bootstrap configuration.
- **Auto Scaling Group (ASG)** — Maintains the required number of EC2 instances and adjusts capacity according to the scaling policy.
- **IAM Role and Instance Profile** — Provide AWS permissions to the EC2 instances without storing AWS credentials on the servers.
- **Amazon CloudWatch / Auto Scaling Metrics** — CPU utilization is used by the target tracking scaling policy to determine when capacity should increase or decrease.

## Project Structure

The Terraform configuration is separated into files based on infrastructure responsibility:

| File | Purpose |
|---|---|
| `provider.tf` | Configures the AWS provider and deployment region. |
| `networking.tf` | Creates the VPC, public and private subnets, Internet Gateway, NAT Gateway, route tables, and routing configuration. |
| `security.tf` | Defines security groups for the Application Load Balancer and EC2 instances. |
| `iam.tf` | Creates the IAM role and instance profile used by the EC2 instances. |
| `launch-template.tf` | Defines the EC2 Launch Template and bootstraps Apache on new instances. |
| `alb.tf` | Creates the Application Load Balancer, Target Group, health checks, and HTTP listener. |
| `autoscaling.tf` | Creates the Auto Scaling Group and CPU-based target tracking scaling policy. |
| `variables.tf` | Defines configurable Terraform input variables such as the administrator CIDR. |
| `outputs.tf` | Displays useful infrastructure information after deployment. |

## Prerequisites

Before deploying this project, ensure the following are installed and configured:

- Terraform
- AWS CLI
- An AWS account with appropriate permissions
- AWS CLI credentials configured for Terraform to use

## Configuration

The administrator IP address used for SSH access is provided through the `admin_cidr` Terraform variable rather than being hard-coded in the Terraform configuration.

Create a local `terraform.tfvars` file:

```hcl
admin_cidr = "YOUR_PUBLIC_IP/32"

## Deployment

After configuring the required variables, the infrastructure can be deployed using the standard Terraform workflow.

### 1. Initialize Terraform

```bash
terraform init
```

Downloads the required Terraform providers and initializes the working directory.

### 2. Format the Configuration

```bash
terraform fmt
```

Formats the Terraform files using Terraform's standard formatting conventions.

### 3. Validate the Configuration

```bash
terraform validate
```

Checks the Terraform configuration for syntax and internal configuration errors.

### 4. Review the Execution Plan

```bash
terraform plan
```

Shows the infrastructure changes Terraform intends to make before any AWS resources are created or modified.

### 5. Deploy the Infrastructure

```bash
terraform apply
```

Creates the AWS infrastructure after reviewing and approving the proposed changes.

### 6. Verify the Deployment

After deployment:

- Confirm that the Application Load Balancer is active.
- Confirm that the registered EC2 targets are healthy.
- Open the ALB DNS name in a browser and verify that the Apache web page is reachable.
- Confirm that the Auto Scaling Group has the expected desired capacity.

## Auto Scaling Test

After deploying the infrastructure and confirming that the application was reachable through the Application Load Balancer, the Auto Scaling configuration was tested under simulated CPU load.

The Auto Scaling Group was configured with:

- **Minimum capacity:** 1 instance
- **Desired capacity:** 1 instance
- **Maximum capacity:** 6 instances
- **Scaling metric:** Average EC2 CPU utilization
- **Target utilization:** 50%

### Load Test

The `stress` utility installed through the EC2 Launch Template was used to generate CPU load on the running instance.

As CPU utilization increased above the target, the Auto Scaling Group responded by launching additional EC2 instances.

During testing, the environment scaled:

```text
1 instance → 2 instances → 4 instances
```

After the CPU load decreased, the Auto Scaling Group reduced capacity toward its desired level.

### What This Demonstrated

The test demonstrated how several AWS services work together:

```text
CPU Load
    ↓
CPU Utilization Metric
    ↓
Auto Scaling Target Tracking Policy
    ↓
Auto Scaling Group
    ↓
Launch Template
    ↓
New EC2 Instances
    ↓
Target Group Health Checks
    ↓
Application Load Balancer
```

This demonstrated that the infrastructure could respond dynamically to increased demand rather than relying on a fixed number of EC2 instances.

## Security Considerations

The project applies several security controls to reduce unnecessary exposure of the EC2 application instances:

- **Private EC2 instances** — Application instances are deployed in private subnets rather than being directly exposed to the internet.
- **Load Balancer security group** — Allows inbound HTTP traffic on port 80 from the internet.
- **EC2 security group** — Allows application traffic on port 80 only from the Application Load Balancer security group.
- **Restricted SSH access** — SSH access on port 22 is limited to the administrator CIDR supplied through the `admin_cidr` Terraform variable.
- **IAM role for EC2** — AWS permissions are provided through an IAM role and instance profile instead of embedding AWS access keys in the EC2 configuration.
- **AWS Systems Manager access** — The EC2 IAM role includes the `AmazonSSMManagedInstanceCore` policy, supporting Systems Manager management of the instances.
- **Sensitive local configuration** — Terraform variable files, state files, private keys, and other local artifacts are excluded from Git through `.gitignore`.

## Cleanup and Cost Awareness

This project creates AWS resources that may incur charges while they are running, including the Application Load Balancer, NAT Gateway, and EC2 instances.

After completing testing, the infrastructure can be removed using:

```bash
terraform destroy
```

Terraform displays the resources that will be destroyed and asks for confirmation before proceeding.

After the destroy operation completes, AWS resources should also be verified to confirm that billable resources from the project are no longer running.

### Cost Considerations

This architecture was created as a hands-on learning project rather than a continuously running production environment.

To control costs:

- Deploy the infrastructure only when needed for testing or demonstration.
- Monitor running EC2 instances and Auto Scaling capacity during load testing.
- Remember that Auto Scaling can launch additional instances automatically.
- Remove the infrastructure after testing with `terraform destroy`.
- Verify that resources such as load balancers and NAT Gateways have been removed after cleanup.

## Lessons Learned

This project strengthened my understanding of how multiple AWS services work together to create scalable infrastructure rather than operating as isolated components.

Key lessons included:

- Understanding the difference between public and private subnets and why application servers can be placed in private subnets.
- Understanding how an Application Load Balancer routes traffic to healthy EC2 instances through a Target Group.
- Using a Launch Template to create consistent EC2 instances automatically.
- Understanding how an Auto Scaling Group manages desired, minimum, and maximum capacity.
- Using CPU utilization and a target tracking policy to automatically adjust capacity.
- Observing Auto Scaling behavior under simulated load rather than only configuring the scaling policy.
- Understanding the role of a NAT Gateway in providing outbound internet access for instances in private subnets.
- Using Terraform to define related AWS infrastructure as code.
- Recognizing the importance of destroying temporary cloud infrastructure after testing to control costs.

## Future Improvements

This project was designed as a hands-on learning environment. Potential improvements for a more production-oriented implementation include:

- Add HTTPS using an SSL/TLS certificate and an HTTPS listener on the Application Load Balancer.
- Use AWS Systems Manager as the primary administrative access method and remove the need for inbound SSH access.
- Use separate NAT Gateways across Availability Zones for greater resilience.
- Store Terraform state remotely with appropriate state locking rather than relying only on local state.
- Add additional monitoring and alerting for infrastructure health and scaling events.
- Add automated Terraform validation and deployment checks through a CI/CD workflow.