// Crate a cluster in aws
resource "aws_eks_cluster" "dharma_eks_cluster" {
    name = "dharma_eks_cluster"
    role_arn = aws_iam_role.role_fordharma_eks_cluster.arn

    vpc_config {
      subnet_ids = [ aws_subnet.private_subnet1.id,aws_subnet.private_subnet2.id ]
                                                                
    }
    depends_on = [ aws_iam_role_policy_attachment.dharma_eks_cluster-AmazonEKSClusterPolicy] 
}
// Bwloe we are creating IAM ROLE for eks-cluster
resource "aws_iam_role" "role_fordharma_eks_cluster" {
    name = "role_fordharma_eks_cluster"
   assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
// below we are attaching the created role
resource "aws_iam_role_policy_attachment" "dharma_eks_cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.role_fordharma_eks_cluster.name
}

//***************************** NOW WE HAVE TO CREATE NODE GROUP********************************


resource "aws_eks_node_group" "nodegroup_dharmaekscluster" {
  cluster_name    = aws_eks_cluster.dharma_eks_cluster.name
  node_group_name = "dharma_node_group"
  node_role_arn   = aws_iam_role.eks_role_for_nodegroup.arn
  subnet_ids      = [ aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id ]


  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node_role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_role-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_role-AmazonEKSWorkerNodePolicy,
  ]
}

//**************IAM ROLES FOR NODE GROUP*************************************
resource "aws_iam_role" "eks_role_for_nodegroup" {
  name = "eks-node-group-dharma_eks"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_role_for_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_role_for_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_role_for_nodegroup.name
}
