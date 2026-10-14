output "LoadBalancer" {
  type  = string
  value = aws_lb.MyLB.dns_name
}
# output "instamce_info" {
#   type = string
#   description = "Ec2 Instance informations"
#   value = aws_instance.web-server-1.id

# }