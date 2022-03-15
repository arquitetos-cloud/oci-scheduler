sudo timedatectl set-timezone America/Sao_Paulo

# Install needed components and configure crontab with correct schedule
sudo yum -y install git
sudo pip3 install oci oci-cli
git clone https://github.com/arquitetos-cloud/oci-scheduler.git
mv oci-scheduler /usr/local/oci-scheduler
crontab /usr/local/oci-scheduler/schedule.cron