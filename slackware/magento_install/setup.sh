#!/bin/bash
# 
# Instalador do Magento CE - O programa que vai facilitar sua vida
# Author Erick Bruno <erickfabiani123@gmail.com>
# Date   2014-10-20
#
# Fluxograma do questionário
#							  INICIO
#			.---------> +----------------+			 
#			`--cancel---|    primeira    |----ESC----+ 
#			.---------> +-------OK-------+			 |
#			`--cancel---|  cria_dominio  |----ESC----+
#			.---------> +-------OK-------+			 |
#			`--cancel---| versao_magento |----ESC----+		 +-----------+
#			.---------> +-------OK-------+			 |-----> | Sai do    |
#			`--cancel---|   create_db    |----ESC----+		 |	Programa |
#			.---------> +-------OK-------+			 |		 +-----------+
#			`--cancel---|	  userdb     |----ESC----+
#			.---------> +-------OK-------+			 |
#			`--cancel---|	  passdb     |----ESC----+
#						+-------OK-------+
#							    FIM
#							
# Fluxograma da instalação
#							  INICIO
#						+-----------------+
#						| Cria pasta raiz |
#						+-------OK--------+
#						|  Baixa Magento  |
#						+-------OK--------+
#						|  Extrai Magento |
#						+-------OK--------+
#						|  Perm. global   |
#						+-------OK--------+
#						|  Perm. Escrita  |
#						+-------OK--------+
#						|	  CRIA DB     |
#						+-------OK--------+
#						|	 Cria V.H.    |
#						+-------OK--------+
#						|	  Seta hosts  |
#						+-------OK--------+
#							    FIM
#
#	


clear

# Global variables
WHOAMI=$(whoami)
_MAGHOST=/var/www/htdocs/magento
INTERVAL=0.050

# BEGIN Functions
die()    { echo "Erro: $*"; exit 1; }
title()  { echo " # - $1 - # "; }
sizeof() { du -s "$1" | cut -f1; }
running(){ ps $1 | grep $1 >/dev/null; }

[ $WHOAMI = 'root' ] || die 'Você deve executar esse script como ROOT!'

proxima=primeira

# Loop princial da aplicação
while : ; do

case "$proxima" in

	# INIT 0: Saudações
	primeira)
	proxima=cria_dominio
	dialog --backtitle 'SETUP MAGENTO CE' \
		--msgbox 'Bem vindo a instalação do Magento CE' 5 40
	;;

	# INIT 1: Cria domínio
	cria_dominio)
	anterior=primeira
	proxima=versao_magento
	DOMAIN=$(dialog --backtitle 'Domínio ' --stdout \
		--inputbox 'Digite o dominio: ' 0 0)	
	;;

	# INIT 2: Escolhendo versão
	versao_magento)
	anterior=cria_dominio
	proxima=create_db
	MAGVERSION=$(dialog --backtitle "Versão " --stdout \
		--menu 'Escolha a versão: ' 0 0 0 \
		'1.7.0.2'	'Stable' 	\
		'1.8.1.0'	'Stable' 	\
		'1.9.0.1' 	'Stable')
	;;

	# INIT 3: Criando Banco de Dados
	create_db)
	anterior=versao_magento
	proxima=userdb
	DBNAME=$(dialog --backtitle 'Setando Banco de Dados ' --stdout \
		--inputbox 'Nome do Banco de Dados: ' 0 0)
	;;

	# Setando usuário do banco
	userdb)
	anterior=create_db
	proxima=passdb
	USERDB=$(dialog --backtitle 'Usuário DB ' --stdout \
		--inputbox 'Usuário do DB: ' 0 0 )
	;;

	# Setando senha do banco
	passdb)
	anterior=userdb
	proxima=info_review
	PASSDB=$(dialog --backtitle 'Senha DB ' --stdout \
		--inputbox 'Senha do DB: ' 0 0 )
	;;

	# INIT 4: Revisão dos dados
	info_review)
	anterior=passdb
	proxima=create_rootdir
	ROOTPROJECT=$(echo $DOMAIN | sed 's/[a-zA-Z0-9]\+\.//')
	dialog --backtitle 'Revisando..' --yesno "Revisando informações\n\nDomínio: $DOMAIN\nVersão: $MAGVERSION\nBanco de Dados: $DBNAME\nUsuário: $USERDB\nSenha: $PASSDB\n--------------------------------\nRaiz: $_MAGHOST/$ROOTPROJECT" 20 40
	;;
	*)
	echo "Desconheço.. $proxima"
	exit
	;;
esac

retorno=$?
[ $retorno -eq 1 ] && proxima=$anterior
[ $retorno -eq 255 ] && break

done