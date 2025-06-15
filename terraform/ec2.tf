# Security Group allowing only your IP for RDP
resource "aws_security_group" "rdp_sg" {
  name        = "allow_rdp"
  description = "Allow RDP from specific IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "RDP from my IP"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["71.218.104.230/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_key_pair" "deployer" {
#   key_name   = "UltimateDashboard"  # Choose a suitable key name
#   public_key = file("C:\\Users\\curle\\.ssh\\universaldashboard.pub")  # Or generate a new key pair locally
# }

# EC2 Windows Server instance with user data to install PowerShell 7
resource "aws_instance" "windows_server" {
  ami                         = data.aws_ami.windows.id
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.default.id
  security_groups         = [aws_security_group.rdp_sg.id]

  user_data = <<-EOF
    <powershell>
    # Download and install PowerShell 7 latest release
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $asset = $latestRelease.assets | Where-Object { $_.name -like "powershell-7.*.win-x64.msi" } | Select-Object -First 1
    $downloadUrl = $asset.browser_download_url
    $dest = "$env:TEMP\\powershell.msi"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $dest
    Start-Process msiexec.exe -ArgumentList "/i `"$dest`" /qn" -Wait

    # Add PowerShell 7 to PATH
    [Environment]::SetEnvironmentVariable("Path", "$Env:Path;C:\Program Files\PowerShell\7", [EnvironmentVariableTarget]Machine)
    </powershell>
EOF

  tags = {
    Name = "UltimateDashboard"
  }
}
