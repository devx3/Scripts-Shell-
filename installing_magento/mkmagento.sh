#
# CBADATA 2013
# inpulse
#
# Script para criacao de ambiente de dominio automatizado, #
# direcionado para o servidor srvweb.ndgdc.cbadata.com.br  #
#

# Questiona usuario sobre informacoes basicas:
# FQDN:
echo -e "Entre com o FQDN do dominio: "; read dnamed
# Nome do bd MySQL:
echo -e "Entre com o nome do banco magento para o dominio $dname: "; read dbmnamed
# Usuario banco/magento:
echo -e "Entre com o nome do Admin do banco magento(max. 10 caracteres !!! ): "; read admnamed
echo -e "...Senha: "; read admpnamed
# URL:
echo -e "Entre com a url da loja(ex: loja.$dnamed): "; read urlnamed


# INIT 0 : Verifica e Inicia processo:

clear
echo -e "# INICIO DO PROCESSO # \n\n > FQDN: $dnamed\n > Database: $dbmname\n > Admin/Senha banco: $admnamed/$admpnamed\n > URL: $urlnamed\n\nConfirma os dados? "
read -p "Pressione y para continuar ou qualquer tecla para sair...  " -n 1
   if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
         echo ""
         exit;
   fi

# INIT 1 : Cria diretorio magento

urlnamedpart=`echo "$urlnamed"|cut -d"." -f1`
echo -e " - OK !\n\n"
echo "${dnamed}|${admnamed}|${admpnamed}|${dbmnamed}|${urlnamed}" >> /opt/listaMagento.txt
echo -n " => Criando diretorios... "
cp -rf /opt/CBA/Install/magento-ce/initc /var/www/html/homepages/$dnamed/$urlnamedpart
chmod -R 775 /var/www/html/homepages/$dnamed
#find /var/www/html/homepages/$dnamed/$urlnamedpart/. -type f -exec chmod 644 {} \;
chmod -R 777 /var/www/html/homepages/$dnamed/$urlnamedpart/media /var/www/html/homepages/$dnamed/$urlnamedpart/app/etc /var/www/html/homepages/$dnamed/$urlnamedpart/var /var/www/html/homepages/$dnamed/$urlnamedpart/var/.htaccess
chown -R apache:ftp /var/www/html/homepages/$dnamed/

echo "OK!"

# INIT 2 : Cria DB MySQL
if [ "$dbmnamed" != "" ]; then
  echo -n " => Criando Database... "
  SQL="CREATE DATABASE IF NOT EXISTS $dbmnamed; GRANT ALL ON $dbmnamed.* TO '$admnamed'@'localhost' IDENTIFIED BY '$admpnamed'; FLUSH PRIVILEGES;"
  `which mysql` -uroot -p'n#sHtsnMk!' -e "$SQL"
  echo -e "OK!\n";
fi

# INIT 3 : Cria Host

echo -n " => Criando host... "
cat >> /etc/hosts << EOF
#HOST $dname magento
127.0.0.1   $urlnamed $dnamed

EOF
cat >> /etc/httpd/vHosts.d/$dnamed.conf << EOF

#$urlnamedpart
<VirtualHost *:80>
        ServerAdmin suporte@newdesigners.com.br
        DocumentRoot /var/www/html/homepages/$dnamed/$urlnamedpart
        ServerName $urlnamed
        ErrorDocument 403 http://www.$dnamed
        ErrorDocument 404 http://www.$dnamed
</VirtualHost>

EOF
echo -e "OK!\n"
service httpd restart




