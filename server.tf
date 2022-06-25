#############################
### Create Nodes
#############################

resource "aws_launch_template" "k3s_server" {
  name_prefix = "${local.name}-server"
  image_id    = local.server_image_id
  user_data   = data.cloudinit_config.k3s_server.rendered
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      encrypted   = true
      volume_type = local.server_volume_type
      volume_size = "50"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = concat([aws_security_group.ingress.id, aws_security_group.self.id], var.extra_server_security_groups)
  }

  tags = {
    Name = "${local.name}-server"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name}-server"
    }
  }
}

resource "aws_autoscaling_group" "k3s_server" {
  name_prefix         = "${local.name}-server"
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = [local.public_subnets[0]]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.use_spot_instance ? 0 : 1
      on_demand_percentage_above_base_capacity = var.use_spot_instance ? 0 : 100
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k3s_server.id
        version            = aws_launch_template.k3s_server.latest_version
      }
      dynamic "override" {
        for_each = var.server_instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }
}

resource "aws_ssm_parameter" "k3sCerts" {
  for_each = toset(["client-ca-key", "client-ca-crt", "server-ca-key", "server-ca-crt", "request-header-ca-key", "request-header-ca-crt"])
  name     = "/k3s/${each.key}"
  type     = "String"
  value    = " "
  lifecycle {
    ignore_changes = [
      "value",
    ]
  }
}

resource "aws_ssm_parameter" "k3sConfig" {
  count = 2
  name  = "/k3s/kubeconfig/${count.index + 1}"
  type  = "String"
  value = " "
  lifecycle {
    ignore_changes = [
      "value",
    ]
  }
}

resource "aws_eip" "this" {
  count = 1
  tags = {
    "Name" = "fixed IP for k3s simple"
  }
}