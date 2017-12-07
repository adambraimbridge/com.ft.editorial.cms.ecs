#!/bin/bash

#Workout enviroment name
case $1 in
	"p")
		export ENV="prod"
		;;
	"int")
		export ENV="prod"
		;;
	"t")
		export ENV="test"
		;;
	"d")
		export ENV="dev"
		;;
	"*")
		export ENV="dev"
		;;
esac

#Adding tomcat user (CMT-1909)
echo "Adding tomcat user"
adduser -c "Tomcat user" -d /var/log/apps -M -s /sbin/nologin -u 1000 -U tomcat
id tomcat
echo

#Adding container logging locations (CMT-1910)
echo "Adding container logs locations"
for s in restapi mis rhelper preview webclient checkin formats mfm image datasource prodarch portalpub postprint eventhandler adorder mms mss msis
do
  mkdir -v /var/log/apps/methode-$s
  chown -v tomcat. /var/log/apps/methode-$s
done
echo

#Adding logging drivers to ECS config (CMT-1949)
echo "Adding logging drivers to ECS config"
echo 'ECS_AVAILABLE_LOGGING_DRIVERS= ["json-file","awslogs","splunk"]' >> /etc/ecs/ecs.config
cat /etc/ecs/ecs.config
echo

#Updating Splunk collector configuration (CMT-1890)
echo "Updating Splunk collector configuration"
cp -v /opt/splunkforwarder/etc/system/local/props.conf{,.bck}
sed -i -e '\#\[source::.../log/(apps|apps/...|restricted/\*/apps|restricted/\*/apps/...)/\*\.log\]#{n; s/\(sourcetype = \)log4j/\1access_combined_time/}' /opt/splunkforwarder/etc/system/local/props.conf
diff -U0 /opt/splunkforwarder/etc/system/local/props.conf{.bck,}
echo
cp -v /opt/splunkforwarder/etc/system/local/inputs.conf{,.bck}
sed -i -e '\#\[monitor:///var/log/apps\]#,+4s/\(whitelist = \).*/\1tomcat_access_.\*\\.log\$/' /opt/splunkforwarder/etc/system/local/inputs.conf
sed -i -e "\#\[monitor:///var/log/apps\]#,+4s/\(index = \).*/\1cms-ecs_$ENV/" /opt/splunkforwarder/etc/system/local/inputs.conf
diff -U0 /opt/splunkforwarder/etc/system/local/inputs.conf{.bck,}
echo

#Restaring Splunk collector
/etc/init.d/splunk restart
echo

echo "CMS ECS customisation DONE"