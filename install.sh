echo -n "- Configurando Timezone "
timedatectl set-timezone America/Sao_Paulo > /dev/status 2>&1
if [ $? = 0 ]; then
  echo "[OK]"
else
  echo "[ERRO]"
  echo 
  echo "Falha na configuração do Timezone."
  echo
  cat /dev/status
  exit 2
fi

echo -n "- Instalando pacotes necessários via yun "
yum -y install git > /dev/status 2>&1
if [ $? = 0 ]; then
  echo "[OK]"
else
  echo "[ERRO]"
  echo 
  echo "Falha na instalação de pacotes."
  echo
  cat /dev/status
  exit 2
fi

echo -n "- Instalando pacotes necessários via pip3"
pip3 install oci oci-cli > /dev/status 2>&1
if [ $? = 0 ]; then
  echo "[OK]"
else
  echo "[ERRO]"
  echo 
  echo "Falha na instalação de pacotes."
  echo
  cat /dev/status
  exit 2
fi

echo -n "- Clonando repositório "
git clone https://github.com/arquitetos-cloud/oci-scheduler.git > /dev/status 2>&1
if [ $? = 0 ]; then
  echo "[OK]"
else
  echo "[ERRO]"
  echo 
  echo "Falha ao clonar o repositorio."
  echo
  cat /dev/status
  exit 2
fi
mv oci-scheduler /usr/local/oci-scheduler
crontab /usr/local/oci-scheduler/schedule.cron
echo
echo "Instalação realizada com sucesso!"
