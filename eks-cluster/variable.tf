variable "vpc_cidr" {
    default = "10.0.0.16"
    description = "vpc cidr block defination"
  
}

variable "availability_zone" {
    default = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1d"]
    description = "availability zones in us-east-1"
}