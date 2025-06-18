resource "aws_efs_file_system" "ecs_persistence" {
  creation_token = "psu-persistence"
  encrypted      = true
  tags = {
    Name = "PSU persistent storage"
  }
}