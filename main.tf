# Definición de los proveedores requeridos y la versión de Terraform mínima
terraform {
  required_providers {
    aws = {
      # Origen del proveedor de AWS
      source  = "hashicorp/aws"  
      # Versión mínima del proveedor de AWS
      version = "~> 4.16"         
    }
  }
  # Versión mínima de Terraform requerida
  required_version = ">= 1.2.0"   
}

# Configuración del proveedor de AWS
provider "aws" {
  # Región de AWS a utilizar
  region     = "us-east-1"           
  # Llave de acceso de AWS (obtenida desde variables)    
  access_key = var.AWS_ACCESS_KEY_ID    
  # Llave secreta de AWS (obtenida desde variables)  
  secret_key = var.AWS_SECRET_ACCESS_KEY  
}

# Definición de un par de claves SSH para la instancia
resource "aws_key_pair" "my_key_pair" {
  # Nombre de la clave
  key_name   = "my-key-pair"          
  # Ruta del archivo de clave pública SSH    
  public_key = file("~/.ssh/id_rsa.pub")   
}

# Definición de un grupo de seguridad para la instancia
resource "aws_security_group" "instance_sg" {
  # Nombre del grupo de seguridad
  name        = "instance_sg"            
  # Descripción del grupo de seguridad  
  description = "Security group for instance"  

  # Reglas de entrada (permisos de acceso a la instancia)
  ingress {
    # Permitir acceso desde cualquier IP (para conexiones SSH)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]            
  }

  ingress {
    # Permitir acceso desde cualquier IP (para solicitudes HTTP)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]            
  }

  # Reglas de salida (permisos de salida desde la instancia)
  egress {
    # Permitir salida a cualquier IP
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]            
  }
}

# Definición de la instancia EC2
resource "aws_instance" "app_server" {
  # ID de la AMI a utilizar
  ami             = "ami-07d9b9ddc6cd8dd30"     
  # Tipo de instancia   
  instance_type   = "t2.micro"                  
  # Nombre de la clave SSH a asociar    
  key_name        = aws_key_pair.my_key_pair.key_name  
  # Grupo de seguridad asociado
  security_groups = [ aws_security_group.instance_sg.name ]  
  # Etiqueta de la instancia
  tags = {
    Name = "Example_terraform"                      
  }
}

# Definición de las salidas (outputs) de la configuración
output "public_ip" {
  # IP pública de la instancia
  value = aws_instance.app_server.public_ip         
}

output "private_ip" {
  # IP privada de la instancia
  value = aws_instance.app_server.private_ip        
}

