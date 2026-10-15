#Get the AWS Region
variable "aws_region" {
  default     = "us-west-1"
  description = "aws region"
}

#Get the CIDR Range
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "default CIDR range of the VPC"
}

#Get the Version of EKS
variable "kubernetes_version" {
  default     = 1.35
  description = "kubernetes version"
}
