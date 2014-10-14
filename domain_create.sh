#!/bin/bash

WHOAMI=$(whoami)
clear
if [ $WHOAMI != 'root' ]
then
        echo -e "# ATENCÃO #\n# VOCÊ DEVE EXECUTAR ESSE SCRIPT COMO ROOT! #"
        exit
fi

read -p "Qual o FQDN? "
DNS=$REPLY

read -p "Qual o caminho para o diretório? "
CAMINHO=$REPLY

clear
echo -e "# INICIO DO PROCESSO DE CONFIGURAÇÃO #\n\nFQDN: $DNS\nDiretorio: $CAMINHO"
read -p "Confirma as informações? (Y/n)" -n 1

if [ ! $REPLY =~ ^[Yy]$ ]
then
        echo ""
        exit
fi
clear

if [ ! -d $CAMINHO ]
then
	mkdir -p $CAMINHO
fi

echo "# INICIANDO CONFIGURAÇÃO DE DOMÍNIO #"
echo "# CRIANDO VIRTUALHOST #"

# INIT 0: Cria o virtualhost
FILENAME=$(echo $DNS | sed -e 's/[a-zA-Z0-9]\+\.//' | cut -d. -f1 )
CNAME=$(echo $DNS | sed -e 's/[a-zA-Z0-9]\+\.//')
touch /etc/apache2/sites-available/$FILENAME
cat >> /etc/apache2/sites-available/$FILENAME << EOF
<VirtualHost *:80>
	ServerName $DNS
	ServerAlias $CNAME
	DocumentRoot $CAMINHO
</VirtualHost>
EOF
echo "# ATIVANDO DOMINIO #"
a2ensite $FILENAME
echo " - OK"
clear

# INIT 1: Cria host
echo "# CONFIGURANDO HOST E IP #"
cat >> /etc/hosts << EOF
# Host $DNS
127.0.0.1	$DNS $CNAME
EOF

echo "# RESTARTANDO SERVIDOR APACHE #"
service apache2 restart


