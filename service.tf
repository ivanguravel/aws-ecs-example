
resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-first-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "strapi/strapi",
      "essential": true,
      "portMappings": [
        {
          "name": "my-first-task-1337-tcp",
          "containerPort": 1337,
          "hostPort": 1337,
          "appProtocol": "http"
        }
      ],
      "mountPoints": [
          {
              "sourceVolume": "vol",
              "containerPath": "/srv/app",
              "readOnly": false
          }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-create-group": "true",
            "awslogs-group": "/ecs/my-first-service",
            "awslogs-region": "eu-west-2",
            "awslogs-stream-prefix": "ecs"
         }
      },
      "environment": [
          {
               "name": "DATABASE_CLIENT",
               "value": "mysql"
          },
          {
               "name": "DATABASE_NAME",
               "value": "mysql"
          },
          {
               "name": "DATABASE_HOST",
               "value": "${var.db_url}"
          },
          {
               "name": "DATABASE_PORT",
               "value": "${var.db_port}"
          },
          {
               "name": "DATABASE_USERNAME",
               "value": "${var.db_user}"
          },
          {
            "name": "DATABASE_PASSWORD",
            "value": "${var.db_password}"
          }
      ],
      "memory": 1024,
      "cpu": 1
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 1024         # Specifying the memory our container requires
  cpu                      = 1         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"

  volume {
    name = "vol"

    efs_volume_configuration {
      file_system_id          = "fs-0ac91b1a06355128c"
      root_directory          = "/"
    }
  }
}

resource "aws_ecs_service" "my_first_service" {
  name            = "my-first-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.my_first_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.my_first_task.family}"
    container_port   = 1337 # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Setting the security group
  }

  depends_on = [
    aws_ecs_cluster.my_cluster,
    aws_alb.application_load_balancer,
    aws_lb_target_group.target_group,
    aws_security_group.service_security_group

  ]
}
