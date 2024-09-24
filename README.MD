***Status:** Work-in-progress. Please create issues or pull requests if you have ideas for improvement.*

# **Kasten K10 full automated Export and Import tasks with Ansible**
Example of using Ansible to automate K10 Export and Import policies to migrate applications to another Kubernetes cluster, or even to be used for Disaster Recovery purposes as a Application Replication solution.

## Summary
This projects demostrates the process importing applications in a DR Kubernetes clusters using Kasten K10 Import Policies.  

All the automation is done using Terraform, Ansible playbooks, and leveraging the [Kasten K10 API](https://docs.kasten.io/latest/api/cli.html).

Kasten Export and Import policies can be used to migrate applications from one Kubernetes cluster to another (for instance from an on-prem Kubernetes cluster to an AWS EKS cluster), or even to provide a the tools for a Disaster Recovery strategy, in fact replicating the applications between two clusters.

## Disclaimer
This project is an example of an deployment and meant to be used for testing and learning purposes only. Do not use in production. 


# Table of Contents

1. [Getting started](#Getting-started)
1. [Prerequisites](#Prerequisites)
1. [Overview of the Export Import strategy for Disaster Recovery](#Overview-of-the-Export-Import-strategy-for-Disaster-Recovery)
1. [Deploying a DR Kubernetes Cluster and Installing Kasten using Terraform](#Deploying-a-DR-Kubernetes-Cluster-and-Installing-Kasten-using-Terraform)
1. [Importing Applications on DR Kubernetes cluster](#Importing-Applications-on-DR-Kubernetes-cluster)

# Getting started

The ability to move an application across clusters is an extremely powerful feature that enables a variety of use cases including Disaster Recovery (DR), Test/Dev with realistic data sets, and performance testing in isolated environments.

In particular, the K10 platform is being built to support application migration and mobility in a variety of different and overlapping contexts:

* Cross-Namespace: The entire application stack can be migrated across different namespaces in the same cluster (covered in restoring applications).
* Cross-Cluster: The application stack is migrated across non-federated Kubernetes clusters.
* Cross-Account: Mobility can additionally be enabled across clusters running in different accounts (e.g., AWS accounts) or projects (e.g., Google Cloud projects).
* Cross-Region: Mobility can further be enabled across different regions of the same cloud provider (e.g., US-East to US-West).
* Cross-Cloud: Finally, mobility can be enabled across different cloud providers (e.g., AWS to Azure).

To learn more about Kasten K10 export policies, please check this link: https://docs.kasten.io/latest/usage/migration.html#exporting-applications
To learn more about Kasten K10 import policies, please check this link: https://docs.kasten.io/latest/usage/migration.html#importing-applications

# Prerequisites

To run this project you need to have some software installed and configured: 

1. The Production Kubernetes cluster must have been using [Kasten K10](https://docs.kasten.io/latest/install/index.html) to backup all applications and cluster-wide resources.
	- At least one [Location Profile](https://docs.kasten.io/latest/usage/configuration.html) must be provided to store applications' backups.
	- This cluster will be used as a **source** containing the applications to be replicated to the **target** cluster.
1. Kasten Policies protecting Kubernetes applications must have been run at least once to provide the required restore points for this project.


# Overview of the Export Import strategy for Disaster Recovery
Replicating applications between two Kubernetes Clusters using Import/Export policies with Kasten, involves the following steps:

1. Deploy a new Kubernetes Cluster and install a fresh K10 instance.  This cluster will be used as a **target** to replicate the applications running on Production Kubernetes Cluster.
1. Provide connection information and credentials for the bucket containing the applications' backups created by Kasten K10 in the Production Cluster.  This bucket will be used as a Location Profile in the Targer Kubernetes cluster where the Applications will be imported to.
1. Create Import Policies in Kasten for every application to be replicated from Production cluster.
1. Restoring the applications from backups using the Import Policies

All these steps will be automated using the Terraform manifests and Ansible playbooks provided in this project.


# Deploying a DR Kubernetes Cluster and Installing Kasten using Terraform
For this project, we will be using Terraform for deploying a Kubernetes cluster and Kasten, including initial Kasten configuration.  The purpose is to automate the deployment of a Kubernetes Cluster for DR purposes.

The resources to be created are the following:
* Cloud network Resources
* AKS/EKS/GKE Cluster
    - Volume Snapshot Class
	- Any other Kubernetes component required for Kasten
* Object Storage (AWS S3 / Azure Blob / Google Storage Account)
* Kasten
    - Token Authentication
    - Access via LoadBalancer
    - EULA agreement
    - Location Profile creation using Object Storage
    - Policy preset samples creation

I'm providing the Terraform manifests for the following options:
* [AWS Elastic Kubernetes Service (EKS)](./Terraform-awseks-kasten/README.md)
* [Google Cloud Kubernetes Engine (GKE)](./Terraform-gcgke-kasten/README.md)
* [Azure Kubernetes Service (AKS)](./Terraform-azureaks-kasten/README.md)

Using this Terraform manifests it is possible to deploy a new Kubernetes Cluster and deploy Kasten with the initial configuration.


# Importing Applications on DR Kubernetes cluster
For this project we will be using Ansible playbooks to automate the creation of Import Policies to "replicate" the Kubernetes applications from Production cluster for DR purposes.

## Recovery duration
The entire recovery process will take approx 10 minutes or more depending on the number of applications and data to recover. 

## Variables
Some deployment variables must be set into the vars files.  Alter the parameters according to your needs:

[Ansible Vault](Ansible-Import/vars/global_vars.yaml) "global_vars.yaml" in the vars folder.
**NOTE**: It is recommended to use Ansible Vaults to keep this data instead of using just a text file, considering all the sensitive data to be kept here.

### Global Variables
| Name                    | Type     | Default value          | Description                                                                                                            |
| ----------------------- | -------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `region`         		  | `string` | `europe-west2`  		  | Bucket region  when applicable             										                                       |
| `storageclass`          | `string` | `csi-sc-k10-aws-csi-eks` | Name of the Storage Class in the target Kubernetes cluster for importing applications.  Mandatory ONLY if the target Kubernetes cluster has a different StorageClass name.
| `frequency`         	  | `string` | `@daily`  	   	  	  | Import frequency                           										                                       |
| `profile_name`          | `string` | `test-bucket`          | Name of the Location Profile in Kasten	                                                                               |
| `bucket_name`           | `string` | `test-bucket`          | Bucket to be used as Location Profile	                                                                               |
| `bucket_type`           | `string` | `gcs`  	  			  | Type of the bucket containing the application's backup data.  Possible values awss3 / azblob / gcs								                                       |


### Variables for AWS S3 based Location Profile (when applicable)

| Name                    | Type     | Default value          | Description                                                                                                            |
| ----------------------- | -------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `aws_access_key_id`     | `string` | `aaaaaaaaa`            | AWS Access Key to add AWS S3 bucket                                                                                    |
| `aws_secret_access_key` | `string` | `aaaaaaaaa`            | AWS Secret Access Key to add AWS S3 bucket                                                                             |   


### Variables for Google Cloud Storage based Location Profile (when applicable)

| Name                    | Type     | Default value          | Description                                                                                                            |
| ----------------------- | -------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `project_id`            | `string` | `gcloud-project-id`    | Google Project ID to add Google Cloud Storage Account                                                                  |


### Variables for Azure Blob based Location Profile (when applicable)

| Name                    | Type     | Default value          | Description                                                                                                            |
| ----------------------- | -------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `tenantID`              | `string` | `aa-431b-b-a7-1012`    | Azure Tenant ID to add Azure Blob                                                                                      |
| `azureclientID`         | `string` | `aaaaaaaaa`            | Azure Client ID to add Azure Blob                                                                                      |
| `Azureclientsecret`     | `string` | `aaaaaaaaa`            | Azure Client Secret to add Azure Blob                                                                                  |
| `azure_storage_key`     | `string` | `aaaaaaaaa`            | Azure Storage Access Key to add Azure Blob                                                                             |
| `azure_storage_env`     | `string` | `AzureCloud`           | AzureCloud is the default in Azure.  More info in https://docs.kasten.io/latest/usage/configuration.html#azure-storage |



## Exporting application data from Production Kubernetes Cluster
A CSV file must be created containing the following information about Kasten Policies on Production Kubernetes Cluster:

* policy: Name of the Kasten backup policy
* string: Import String reported by every Kasten backup Policy
* app: Name of the app protected by the policy

A sample CSV file is provided in [Ansible-Import/createpolicy/import_details.csv](Ansible-Import/createpolicy/import_details.csv)

The name and format of this file must not changed.

This file could be automatically generated using Kubectl, like the following example.

```
kubectl get policy -n kasten-io -o jsonpath='{range .items[*]}{.metadata.name}{","}{.spec.actions[?(@.action=="export")].exportParameters.receiveString}{","}{.spec.selector.matchExpressions[0].values[0]}{"\n"}{end}' > import_details.csv
```

**NOTE**: The CSV file MUST contain headers like the provided sample.  Without headers the Ansible playbook will fail.

## Importing Applications into the DR Kubernetes Cluster
Using K10 Import policies involves the following sequence of actions:

1. [Configuring Locations Profiles](Ansible-Import/01_k10_create_locprofile.yaml) 
Run the following command:

```
ansible-playbook   01_k10_create_locprofile.yaml
```

In case you are using Ansible Vaults for variables (recommended), please run the following command instead:

```
ansible-playbook   --ask-vault-pass 01_k10_create_locprofile.yaml
```

1. [Configure Import Policies](Ansible-Import/02_k10_create_imports.yaml) for every application to be imported in the DR Cluster.   In this project, the Ansible playbook will run the following actions:
	  - Create the import policy for every application to be imported.  The list of applications and the required data is provided through a [CSV FIle](Ansible-Import/createpolicy/import_details.csv)
	  - Add the Import String from the CSV File.
	  - Set the Import Policy to restore the entire app and its data after importing it.


Run the following command:

```
ansible-playbook   02_k10_create_imports.yaml 
```

In case you are using Ansible Vaults for variables (recommended), please run the following command instead:

```
ansible-playbook   --ask-vault-pass 02_k10_create_imports.yaml
```

**Important**: The playbooks must be run in the mentioned order in order to make the recovery process works.

