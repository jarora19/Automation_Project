#!/bin/bash

name="Jatin"
s3_bucket="upgrad-jatin"

apt update -y

if [[ apache2 = $(dpkg --get-selections apache2 | awk '{print $1}') ]];
then
    echo "Apache2 is already installed."
else
   sudo apt install apache2 -y
fi

running=$(systemctl status apache2 | grep active | awk '{print $3}' | tr -d'()')

if [[ running != ${running} ]];
then
     systemctl start apache2
fi

enabled=$(systemctl is -enabled apache2 | grep "enabled")
if [[ enabled != ${enabled} ]];
then
      systemctl enable apache2
fi
timestamp=$(date '+%d%m%Y-%H%M%S')

cd /var/log/apache2
tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar *.log

if [[ -f /tmp/${name}-httpd-logs-${timestamp}.tar ]];
then 
    aws s3 cp /tmp/${name}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar
fi

if [ -e /var/www/html/inventory.html ]
then
	echo "File is present"
else 
	touch /var/www/html/inventory.html
	echo "<table>
    <tr>
        <th>Log Type</th>
        <th>Time Created</th> 
        <th>Type</th>  
        <th>Size</th>
    </tr>
    </table>" >> /var/www/html/inventory.html

fi
sed -i '$d' /var/www/html/inventory.html

echo "<tr>
        <td>httpd-logs</td>
        <td>${timestamp}</td>
        <td>tar</td>
        <td>`du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}'`</td>
    </tr>
    </table>" >>  /var/www/html/inventory.html

if [ -e /etc/cron.d/automation ]
then
        echo "cron job is there"
else
        touch /etc/cron.d/automation
        echo "0 0 * * * root /root/Automation_Project/automation.sh" > /etc/cron.d/automation
        echo "new cron job created"
fi

exit 0
