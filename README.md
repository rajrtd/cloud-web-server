# IaC Cloud Web Server
### Creating a Ruby on Rails web server in the cloud with AWS and Terraform.

## Task
For this project I was tasked with creating a web server on the cloud. The server will be using Ruby on Rails to display a "Hello World" in a header. The cloud architecture for this project needed to roughly comply with this diagram (The services on the left of the architecture were optional services we could include):

![Original Diagram](images/original-diagram.png)

<strong>Note:</strong> The primary and secondary databases in this project are redundant. They are there just to show my technical ability in setting up the servers. The secondary database is a read-only replica.

## Design

I altered the architecture to avoid using some of the AWS services that incur costs. However, I was able to use an environment that paid for the costs, so some of my services do incur a cost.

#### First Iteration:

![First Iteration](images/diagram-v1.png)

#### Second Iteration:

![Alt text](images/diagram-v2.png)

The design changes I made to this iteration was to put the EC2 instances into private subnets instead of public, as this would be better security practice.

#### Third Iteration:
![Alt text](images/diagram-v3.png)

In this iteration I've included an extra route table for each instance in each private subnet to route them to the NAT Gateways in public subnet 1 and 2, as it is not a multi-az service.

I've also removed 

#### Fourth Iteration:

The inbound ports that should be kept open are 443, 80, 3000 in SG 1

I intended on using the internet gateway instead of the transit gateway.

### Subnetting

My master CIDR block for this architecture was <strong>192.168.0.0/16</strong> I was able to subnet this across 3 tiers.

- The load balancers/NAT Gateway tier - <strong>192.168.0.0/18</strong>
- Application tier - <strong>192.168.64.0/18</strong>
- Database tier - <strong>192.168.128.0/18</strong>

The CIDR blocks for the architecture are as follows: 

#### Public Subnets

NAT Gateway and application load balancer belong in these subnets

Public Subnet 1 = <strong>192.168.0.0/19</strong> <br>
Public Subnet 2 = <strong>192.168.32.0/19</strong>

#### Private Subnets

EC2 instances/Auto-scaling group belong in private subnet 1 & 2
<br>
Amazon RDS databases belong in private subnet 3 & 4

Private Subnet 1 = <strong>192.168.64.0/19</strong> <br>
Private Subnet 2 = <strong>192.168.96.0/19</strong> <br>
Private Subnet 3 = <strong>192.168.128.0/19</strong> <br>
Private Subnet 4 = <strong>192.168.160.0/19</strong>  

#### Security Groups

Security Group 1 (NAT Gateway & ALB) = <strong>192.168.0.0/18</strong> <br>
Security Group 2 (EC2 Instances) = <strong>192.168.64.0/18</strong> <br>
Security Group 3 (Databases) = <strong>192.168.128.0/18</strong> 

## Objectives

- Deploy the web server with a user data script on the instances.
- Create an autoscaling group that can add/remove an EC2 instance depending on the load on the CPU.
- Create a read-only Amazon RDS database that uses MySQL.
- Create an application load balancer that can switch between instances depending on the health status of the instances as well as work with the auto-scaling group.
- Create EC2 instances that can switch to the secondary database given that the primary is unhealthy.

## Challenges:
My original goal was to test my user data scripts, I had a routing issue, checked all my routing configurations, confident it’s all fixed, currently facing a 502 bad gateway error. Did some research and found that the error is probably with my application load balancer, certain the configuration is correct, but I’m trying to currently attach an S3 bucket to the load balancer so I can check the CloudWatch logs to see what the error is, but I’m having difficulty with that because the bucket is not being made, and I think it might be a policy issue.
If I’m unable to solve this problem for now, I’ll move onto setting up the primary and secondary databases.
Fixed S3 bucket issue to the ALB’s access and connection logs, now I just need to decipher them.

Going to try and figure out why my instance is supposedly unhealthy
Logs show that it is forwarding to the correct port and ip address.
Issues with the user data script, some commands had to be altered, was using 

Biggest problems:

- Bad gateway (found out need a health check)
- User data scripts
- Couldn’t clone repo properly
- Incorrect dependencies
- Incorrect versioning
- Went back and forth, trying it on Amazon Linux 2 and Ubuntu-22.04
- Security group port, I think for Ubuntu	

## Limitations

The monthly costs of the 