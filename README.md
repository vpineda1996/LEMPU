##LEMPU

Script to install LEMP or LAMP (Nginx, MySQL, PHP) in Userland.  It isn't bulletproof but it has been designed to be as unobtrusive and universal as possible.

###Instalation

Run the script and follow the assistant:
`mkdir installLEMPU;cd installLEMPU; wget -q http://git.io/2j2s6g --no-check-certificate -O LEMPU.sh; chmod +x LEMPU.sh; ./LEMPU.sh`

###Dependencies
- You must be able to complie as user. Most seedbox providers who support ssh login have compilers.
- If you intent to use authentication services with NGINX you must be able to run crypt. This command comes with mcrypt directory, else it isn't necesary.
- Confirmed shared environments that this script works
  - Whatbox.ca
