# Parcativa Terraform + Ansible 
Se Terraform para aprovisionar una máquina virtual (Instancia EC2) con Ubuntu 22.04 LTS y Ansible para configurarla como servidor Nginx con PHP.

## instalacion 
usando WSL o linux
### para terrafor
- Descargar y añadir la clave GPG de HashiCorp
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```
- Añadir el repositorio de HashiCorp a la lista de fuentes de software
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
- Actualizar la lista de paquetes e instalar Terraform
```bash
sudo apt update && sudo apt install terraform
```
- Verificar la instalación de Terraform
```bash
terraform --version
```

###  ansible
- Utiliza el gestor de paquetes apt para instalar Ansible:
```bash
sudo apt install ansible
```
- Verifica la instalación:
```bash
ansible --version
```

## Configurar accesos de AWS
- crearse una cuenta de AWS
- crear un usuario IAM 
- asignarle la politica de ***AmazonEC2FullAccess*** al usuario creado
- ir a credeciales de seguridad y crear claves de acceso para le usuario y guardar el ***id de acceso de AWS*** y la ***llave de acceso secreto*** para poder hacer la conecion al ususario.

## Par de llaves SSH
- creamos un par de llaves publica y privada para hacer la conexion a la instacia por SSH
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
```

## Declaracion de la infraestructura
en un archivo main.tf declaramos la infraestructura a utilizar 
``` hcl
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
```
Creamos los siguientes archivos
- ***variables.tf:*** colocar aca las llaves obtenidas del usuario IAM de AWS
```hcl
    AWS_ACCESS_KEY_ID="id de acceso de AWS"
    AWS_SECRET_ACCESS_KEY="llave de acceso secreto de AWS"
```
- ***terraform.tfvars***
```hcl
    variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key ID"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Access Key"
}
```

tenidno la declaracion de la infraestructura lista realizamos los siguientes comandos 
- ***Inicializar Terraform:*** En el directorio donde tienes tu archivo main.tf, ejecuta el siguiente comando para inicializar Terraform y descargar los plugins necesarios:
```bash
terraform init
```
- ***Verificar Cambios:*** Antes de aplicar los cambios, es recomendable ver qué cambios se van a realizar en tu infraestructura. Puedes hacerlo ejecutand
```bash
terraform plan
```
- ***Aplicar Cambios:*** Si estás satisfecho con los cambios propuestos, puedes aplicarlos ejecutando:
```bash
terraform apply
```
![Texto alternativo](/images/terraform_apply.PNG)

podemos verificar en la plataforma de AWS que los recursos creados como la instacia EC2 y su grupo de seguriad estan disponibles.

![Texto alternativo](/images/aws.PNG)

podriamos conectarnos a nuestra instacia por SSH de la siguiente manera:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<ip_publica_de_tu_instancia>
```
![Texto alternativo](/images/ssh%20conection.PNG)

## Configuramos con Ansible
configuramos un servidor Nginx con PHP usando ansible
- Entramos la directorio ansible del repo.
```bash
cd ansible
```
- En el archivo ***inventory*** ubicamos en el lugar correspondiente la ip publica de la instancia 
```txt
    [servers]
    server1 ansible_host="IP publica de la instancia" ansible_ssh_private_key_file=~/.ssh/id_rsa
```
- aplicamos el comando que ejecutara las tareas correpondientes para configurar el server Nginx con PHP en la instacia
```bash
ansible-playbook -i inventory nginx.yaml
```
![Texto alternativo](/images/ansible.PNG)

Al completarse las tareas ya podriamos ver la pagina de inicio que debe mostra nuestro server en la url ***http://3.81.121.192/test.php*** (cambia la ip del link por la ip publica de la instacnia lanzada)

![Texto alternativo](/images/php_info.PNG)