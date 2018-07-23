#!/bin/bash
JAVA_HOME=/usr/java/jdk1.7.0_67-cloudera
export JAVA_HOME
export PATH=${PATH}:${JAVA_HOME}/bin


HOST_LIST=hosts.txt

# Level 1 SSL/TLS
keytool -genkeypair -alias {{ alias_cmhost }} -keyalg RSA -keysize 2048 -dname 'cn={{cn}}, ou={{ou}},o={{o}}, l={{l}}, st={{st}}, c={{c}}' -keypass {{keypass}} -keystore keystore.jks -storepass {{storepass}} -validity 360
# Level 2 SSL/TLS
keytool -exportcert -keystore keystore.jks -alias {{ alias_cmhost }} -file scm-server.der -storepass {{storepass}}
openssl x509 -out scm-server.pem -in scm-server.der -inform der
# Level 3 SSL/TLS
for HOST in $(cat ${HOST_LIST});
do

	openssl genrsa -des3 -passout pass:{{ agent_keystore_password }} -out ${HOST}.key 2048
	openssl req -new -x509 -days 1095 -key ${HOST}.key -out ${HOST}.pem -passin pass:{{ agent_keystore_password }} -config <(
cat <<-EOF
[ req ]
prompt = no
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
C={{c}}
ST={{st}}
L={{ l }}
O={{o}}
OU={{ou}}
CN=${HOST}
EOF
)
	keytool -keystore keystore.jks -import -alias ${HOST} -file ${HOST}.pem  -storepass {{storepass}} -noprompt
done

cp -f ${JAVA_HOME}/jre/lib/security/cacerts ${JAVA_HOME}/jre/lib/security/jssecacerts

keytool -exportcert -alias {{ alias_cmhost }} -keystore keystore.jks -file ${JAVA_HOME}/jre/lib/security/jssecacerts -storepass {{storepass}}

cp keystore.jks truststore.jks
keytool -storepasswd -new {{ truststore_password }} -keystore truststore.jks -storepass {{storepass}}
cp -f keystore.jks /etc/pki/cloudera/jks/
cp -f truststore.jks /etc/pki/cloudera/x509
chown -R cloudera-scm:cloudera-scm /etc/pki/cloudera



