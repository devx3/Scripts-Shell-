#!/bin/bash
clear

# Global variables
WHOAMI=$(whoami)
_MAGHOST=/var/www/htdocs/magento

# BEGIN Functions
die()    { echo "Erro: $*"; exit 1; }
title()  { echo " # - $1 - # "; }
sizeof() { du -s "$1" | cut -f1; }
running(){ ps $1 | grep $1 >/dev/null; }

[ $WHOAMI = 'root' ] || die 'Você deve executar esse script como ROOT!'

# -------------------------------

# INIT 0: Iniciando instalação

dialog \
	--title  "$(title "BEM-VINDO")" \
	--msgbox "\nBem Vindo a instalação do MAGENTO CE em seu servidor.\n\nEsse setup provê uma instalação completa do Magento em seu servidor, definindo:\n\n Download e instalação\n Criação do BD\n Criação do VirtualHost" 20 80

# Verifica se existe pasta do magento
if [ ! -d $_MAGHOST ]
then
	dialog \
		--title "$(title "INFO")" \
		--yesno "\n O diretório $_MAGHOST não existe, deseja cria-lo?" 10 50
	#echo $? && exit

	if [[ $? == 1 ]]
	then
		exit
	fi
	mkdir -p $_MAGHOST
	[ -d $_MAGHOST ]; dialog --title "$(title "INFO")" --msgbox 'Diretório criado com sucesso!' 10 20  || die "Erro ao criar diretório";
fi

MAGVERSION=$(dialog						 			 \
				--title "$(title "SETUP")" 			 \
				--stdout							 \
				--menu 'Escolha a versão do magento' \
				10 30 10 						 	 \
				'1.7.0.2'	'Stable' 				 \
				'1.8.1.0'	'Stable' 				 \
				'1.9.0.1' 	'Stable')

# Caso não seja escolhido uma versão
if [ $MAGVERSION == "" ]
then
	# Pega a ultima release
	MAGVERSION="1.9.0.1"
fi

# INIT 1: Checando dados
DOMAIN=$(dialog --stdout --inputbox 'Qual o domínio?' 0 0)
DOMAINBD=$(dialog --stdout --inputbox 'Qual o Banco de Dados MySQL?' 0 0)
USER=$(dialog --stdout --inputbox 'Usuário:' 0 0)
PASS=$(dialog --stdout --inputbox 'Senha:' 0 0)

DIRROOT=$(echo $DOMAIN | sed -e 's/[a-zA-Z0-9]\+\.//')

dialog						  \
	--title "$(title "INFO")" \
	--yesno "Confirmação dos dados:\n\nVersão do Magento: $_MAGVERSION\nDiretório Raiz: $_MAGHOST/$DIRROOT\nDominio: $DOMAIN\nBanco de Dados: $DOMAINBD\nUsuário: $USER\nSenha: $PASS\n" \
	0 0

# Caso escolhido não, sai da aplicação
[[ $? == 1 ]] && die "Saindo da aplicação"

# INIT 1: BAIXANDO MAGENTO E CRIANDO DIRETÓRIOS
cd $_MAGHOST

#Baixa o magento

MAGFILENAME="magento-$MAGVERSION.tar.gz"
DIRNAME="magento"
dialog --msgbox "Aguarde enquanto terminamos o download..." 0 0
wget http://www.magentocommerce.com/downloads/assets/$MAGVERSION/$MAGFILENAME

TOTALSIZE=$(sizeof $MAGFILENAME)
INTERVAL=0.032

tar -xvzf magento-$MAGVERSION.tar.gz
EXTRACTPID=$!

(while running $EXTRACTPID 
	do
		EXTRAIDO=$(sizeof $DIRNAME)
		PERCENT=$((EXTRAIDO*100/TOTALSIZE))
		echo $PERCENT
		sleep $INTERVAL
	done
echo 100) | dialog --title "$(title "INSTALAÇÃO")" --gauge "Instalando..." 8 40 0
exit 1;

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
