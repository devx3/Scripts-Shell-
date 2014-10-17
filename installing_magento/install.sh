#!/bin/bash
clear

WHOAMI=$(whoami)

if [ $WHOAMI != 'root' ]
then
	echo -e "# ATENCÃO #\n# VOCÊ DEVE EXECUTAR ESSE SCRIPT COMO ROOT! #"
	exit
fi

_MAGHOST=/var/www/magento
echo "# INICIANDO INSTALAÇÃO DO MAGENTO #"
# Verifica se existe pasta do magento
if [ ! -d $_MAGHOST ]
then
	clear
	echo "# INFORMAÇÕES #"
	echo -e "Pasta para o magento inexistente"
	read -p "Deseja criar a pasta? (y/n)" -n 1
	
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		exit
	fi
	echo -n " => CRIANDO DIRETÓRIOS..."
	mkdir -p $_MAGHOST
fi

echo "# VERSÃO DO MAGENTO #"
echo -e "1.7.0.2 - Stable Version\n1.8.1.0 - Stable Version\n1.9.0.1 - Stable Version\n"
read -p "Digite uma das versões acima: "
MAGVERSION=$REPLY

# Caso não seja escolhido uma versão
if [ $MAGVERSION == "" ]
then
	# Pega a ultima release
	MAGVERSION="1.9.0.1"
fi

# INFORMAÇÕES BÁSICAS
echo -n "Qual o dominio? "; read DOMAIN
#Nome do Banco Mysql
echo -n "Qual o Banco de Dados MySQL? "; read DOMAINBD

#usuário
echo -n "Usuário: "; read USER;
#senha
echo -n "Senha: "; read PASS

#INIT 0 : Inicia processo

clear
echo -e " # INICIO DO PROCESSO DE INSTALAÇÃO #\n\nDiretório Raiz: $_MAGHOST/$DOMAIN\nDominio: $DOMAIN\nBanco de Dados: $DOMAINBD\nUsuário: $USER\nSenha: $PASS\n"
echo ''
read -p "Confirma as informações? (y/n)" -n 1

if [ ! $REPLY =~ ^[Yy]$ ]
then
	echo ""
	exit
fi
clear

# INIT 1: BAIXANDO MAGENTO E CRIANDO DIRETÓRIOS
cd $_MAGHOST

#Baixa o magento
echo "# INICIANDO DOWNLOAD DO MAGENTO #"
wget http://www.magentocommerce.com/downloads/assets/$MAGVERSION/magento-$MAGVERSION.tar.gz

tar -xvzf magento-$MAGVERSION.tar.gz
mv magento/ $DOMAIN && rm *.tar.gz

# Setando permissão 755 geral
chmod -R 755 $DOMAIN

# Seta permissões para pasta de imagens, módulos, logs...
chmod -R 777 $DOMAIN/media $DOMAIN/app/etc $DOMAIN/var/ $DOMAIN/var/.htaccess $DOMAIN/includes $DOMAIN/downloader
echo ' - OK!';
sleep 1
clear
# INIT 2: CRIANDO BANCO DE DADOS
# cria tabela no banco de dados
echo -n "# CRIANDO BANCO DE DADOS #"
SQL="CREATE DATABASE IF NOT EXISTS ${DOMAINBD}"
mysql -uroot -proot -e "${SQL}"

echo ' - OK!';
sleep 1
clear

# INIT 3: CRIANDO HOST
echo -n " => CRIANDO HOST..."
cat >> /etc/hosts << EOF
#Host $DOMAIN Magento
127.0.0.1 $DOMAIN
EOF
cat >> /etc/apache2/sites-available/$DOMAIN.conf  << EOF
<VirtualHost *:80>
	DocumentRoot $_MAGHOST/$DOMAIN
	ServerName $DOMAIN
</VirtualHost>
EOF

echo ' - OK!'

# INIT 4: ATIVANDO DOMINIO
echo "# ATIVANDO DOMÍNIO #"
a2ensite $DOMAIN.conf

echo "# RESTARTANDO SERVIDOR APACHE #"
service apache2 restart

echo " - CONCLUÍDO!"
