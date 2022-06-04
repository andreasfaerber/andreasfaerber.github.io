sudo apt update
sudo apt -y dist-upgrade
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo apt -y install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin apache2-utils
sudo docker run hello-world
sudo apt -y install docker-compose
sudo systemctl reset-failed docker
sudo systemctl restart docker
sudo docker ps
mkdir docker-teslamate
cd docker-teslamate
mkdir import
sudo mkdir -p /docker-data/teslamate/teslamate-db
sudo mkdir -p /docker-data/teslamate/grafana-data
sudo mkdir -p /docker-data/teslamate/mosquitto-conf
sudo mkdir -p  /docker-data/teslamate/mosquitto-data
curl -o ~/docker-teslamate/docker-compose.yml https://blog.abgefaerbt.de/assets/files/teslamate-docker-compose.yml
curl -o ~/docker-teslamate/docker-compose.override.yml https://blog.abgefaerbt.de/assets/files/teslamate-docker-compose.override.yml
curl -o ~/docker-teslamate/.env https://blog.abgefaerbt.de/assets/files/teslamate.env
nano .env
htpasswd -B -c .htpasswd teslamate
