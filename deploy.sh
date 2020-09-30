echo "Stop jenkins-local."
systemctl is-active --quiet jenkins-local && systemctl stop jenkins-local

docker-compose down

if [ ! -d "jenkins_data" ]; then
    echo "Create jenkins_data folder."
    mkdir jenkins_data
    echo "Set owner of jenkins_data/."
    chown -R jenkins:0 jenkins_data/
    echo "jenkins_data/ configured."
fi

if [ ! -d "jenkins_plugins" ]; then
    echo "Create jenkins_plugins folder."
    mkdir jenkins_plugins
    echo "Set owner of jenkins_plugins/."
    chown -R jenkins:0 jenkins_plugins/
    echo "jenkins_plugins/ configured."
fi

echo "Install plugins."
tag=$(get_octopusvariable "Project.Jenkins.ServerTag")

docker run --volume "$(pwd)/jenkins-plugins:/usr/share/jenkins/ref/plugins" \
    bitnami/jenkins:$tag \
    install-plugins.sh octopusdeploy:latest custom-tools-plugin:latest

docker-compose pull
docker-compose up -d

mv jenkins-local.service /etc/systemd/system
mv jenkins.local /etc/nginx/sites-available

if [ ! -e "/etc/nginx/sites-enabled/jenkins.local" ]; then
    echo "Create /etc/nginx/sites-enabled/jenkins.local."
    ln -s /etc/nginx/sites-available/jenkins.local /etc/nginx/sites-enabled/jenkins.local
fi

echo "Start jenkins-local."
systemctl is-enabled --quiet jenkins-local || systemctl enable jenkins-local
systemctl start jenkins-local
echo "Reload systemctl daemon."
systemctl daemon-reload
echo "Restart nginx."
systemctl restart nginx

write_highlight "[jenkins.local](https://jenkins.local)"

exit 0
