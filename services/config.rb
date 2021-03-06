## This file was auto-generated by CloudCoreo CLI
## This file was automatically generated using the CloudCoreo CLI
##
## This config.rb file exists to create and maintain services not related to compute.
## for example, a VPC might be maintained using:
##
## coreo_aws_vpc_vpc "my-vpc" do
##   action :sustain
##   cidr "12.0.0.0/16"
##   internet_gateway true
## end
##

coreo_aws_vpc_vpc "${VPC_NAME}" do
  action :find
  cidr "${VPC_OCTETS}/16"
end

coreo_aws_vpc_routetable "${PRIVATE_ROUTE_NAME}" do
  action :find
  vpc "${VPC_NAME}"
  number_of_tables 3
  tags [
        "Name=${PRIVATE_ROUTE_NAME}"
       ]
end

coreo_aws_vpc_subnet "${PRIVATE_SUBNET_NAME}" do
  action :find
  route_table "${PRIVATE_ROUTE_NAME}"
  vpc "${VPC_NAME}"
end

coreo_aws_vpc_routetable "${PUBLIC_ROUTE_NAME}" do
  action :find
  vpc "${VPC_NAME}"
end

coreo_aws_vpc_subnet "${PUBLIC_SUBNET_NAME}" do
  action :find
  route_table "${PUBLIC_ROUTE_NAME}"
  vpc "${VPC_NAME}"
end

coreo_aws_ec2_securityGroups "thumbor-elb-sg" do
  action :sustain
  description "Open https to the world"
  vpc "${VPC_NAME}"
  allows [ 
          { 
            :direction => :ingress,
            :protocol => :tcp,
            :ports => ["0..65535"],
            :cidrs => ${VPN_ACCESS_CIDRS},
          },{ 
            :direction => :ingress,
            :protocol => :udp,
            :ports => ["0..65535"],
            :cidrs => ${VPN_ACCESS_CIDRS},
          },{ 
            :direction => :ingress,
            :protocol => :icmp,
            :ports => ["0..65535"],
            :cidrs => ${VPN_ACCESS_CIDRS},
          },{ 
            :direction => :egress,
            :protocol => :tcp,
            :ports => ["0..65535"],
            :cidrs => ${VPN_ACCESS_CIDRS},
          },{ 
            :direction => :egress,
            :protocol => :udp,
            :ports => ["0..65535"],
            :cidrs => ${VPN_ACCESS_CIDRS},
          },{ 
            :direction => :egress,
            :protocol => :icmp,
            :ports => ["0..65535"],
            :cidrs => ${VPN_ACCESS_CIDRS},
          }
    ]
end

coreo_aws_ec2_elb "thumbor-elb" do
  action :sustain
  type "public"
  vpc "${VPC_NAME}"
  subnet "${PUBLIC_SUBNET_NAME}"
  security_groups ["thumbor-elb-sg"]
  listeners [
             {
               :elb_protocol => 'tcp', 
               :elb_port => 80, 
               :to_protocol => 'tcp', 
               :to_port => 80
             },
            ]
  health_check_protocol 'tcp'
  health_check_port "80"
  health_check_timeout 5
  health_check_interval 120
  health_check_unhealthy_threshold 5
  health_check_healthy_threshold 2
end

coreo_aws_ec2_securityGroups "thumbor-sg" do
  action :sustain
  description "Open connections to the world"
  vpc "${VPC_NAME}"
  allows [ 
          { 
            :direction => :ingress,
            :protocol => :tcp,
            :ports => ["0..65535"],
            :groups => ["thumbor-elb-sg"],
          },{ 
            :direction => :ingress,
            :protocol => :udp,
            :ports => ["0..65535"],
            :groups => ["thumbor-elb-sg"],
          },{ 
            :direction => :ingress,
            :protocol => :icmp,
            :ports => ["0..65535"],
            :groups => ["thumbor-elb-sg"],
          },{ 
            :direction => :ingress,
            :protocol => :tcp,
            :ports => [22],
            :cidrs => ${VPN_SSH_ACCESS_CIDRS},
          },{ 
            :direction => :egress,
            :protocol => :tcp,
            :ports => ["0..65535"],
            :cidrs => ["0.0.0.0/0"],
          },{ 
            :direction => :egress,
            :protocol => :udp,
            :ports => ["0..65535"],
            :cidrs => ["0.0.0.0/0"],
          },{ 
            :direction => :egress,
            :protocol => :icmp,
            :ports => ["0..65535"],
            :cidrs => ["0.0.0.0/0"],
          }
    ]
end

coreo_aws_iam_policy "thumbor-s3" do
  action :sustain
  policy_name "thumborS3"
  policy_document <<-EOH
{
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
          "*"
      ],
      "Action": [ 
          "s3:*"
      ]
    }
  ]
}
EOH
end

coreo_aws_iam_instance_profile "thumbor" do
  action :sustain
  policies ["thumbor-s3"]
end

coreo_aws_ec2_instance "thumbor" do
  action :define
  upgrade_trigger "1"
  image_id "${THUMBOR_AMI_ID}"
  size "${THUMBOR_INSTANCE_TYPE}"
  security_groups ["thumbor-sg"]
  ssh_key "${THUMBOR_SSH_KEY_NAME}"
  role "thumbor"
end

coreo_aws_ec2_autoscaling "thumbor" do
  action :sustain 
  minimum 1
  maximum 1
  server_definition "thumbor"
  subnet "${PRIVATE_SUBNET_NAME}"
  elbs ["thumbor-elb"]
end
