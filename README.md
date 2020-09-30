# jenkins.local

Configure a local instance of Jenkins using Docker Compose, systemd, and Nginx.

## Instructions

### Requirements

This configuration is intended to run on a Linux server with [docker-compose](https://docs.docker.com/compose/), [nginx](https://www.nginx.com/), and [systemd](https://systemd.io/) installed.

It is developed and tested against Ubuntu 20.04.

### Certificates

You will need a certificate for `jenkins.local`. At the bottom of [this page](https://letsencrypt.org/docs/certificates-for-localhost/) there are instructions for creating a self-signed certificate.

You can create a key for `jenkins.local` by modifying a few values.

```
openssl req -x509 -out jenkins.crt -keyout jenkins.key \
  -newkey rsa:2048 -nodes -sha256 \
  -subj '/CN=jenkins.local' -extensions EXT -config <( \
   printf "[dn]\nCN=jenkins.local\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:jenkins.local\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```

Make note of where you store these files. You'll need to provide the paths to the files in the variables step later.

You'll need to import the certificate to any client computer or browser used to connect to https://jenkins.local. Chrome will still give you a warning because the certificate is self-signed.

### Octopus Instance

This configuration is meant to be deployed by Octopus. [Octopus Server and Octopus Cloud](https://octopus.com/pricing/overview) are free to use for up to ten targets. The deployment process depends on the YAML substitution feature so you will need Octopus 2020.4.0 or newer.

The Linux server will need a [Tentacle](https://octopus.com/docs/infrastructure/deployment-targets/linux/tentacle) installed and registed to your instance.

### GitHub External Feed

In your Octopus instance, navigate to **Library > External Feeds**.

Add a new feed. Choose **GitHub Repository Feed**.

The default settings will work. No credentials are required.

![GitHub Feed Settings](images/github-feed.png)

Test the feed by searching for **OctopusDeployLabs/jenkins.local**.

### Project Variables

Create a new project and navigate to **Variables > Project**. Configure the following variables.

| Variable Name                                                     | Type      |  Suggested Value                 | Notes                                                                             |
|-------------------------------------------------------------------|-----------|----------------------------------|-----------------------------------------------------------------------------------|
| Project.Nginx.CertificateKeyLocation                              | Text      | The path to your certificate key |                                                                                   |
| Project.Nginx.CertificateLocation                                 | Text      | The path to your certificate     |                                                                                   |
| Project.Jenkins.InstallLocation                                   | Text      | /srv/jenkins.local               |                                                                                   |
| Project.Jenkins.Port                                              | Text      | 8090                             | Any unused port should work.                                                      |
| Project.Jenkins.ServerTag                                         | Text      | 2-debian-10                      | You can make this a prompted variable if you want to override tag at deploy time. |
| Project.Jenkins.TrustStorePassword                                | Sensitive | a strong password                | See below                                                                         |
| Project.Jenkins.ServiceDescription                                | Text      | Jenkins - Local                  |                                                                                   |
| services:jenkins:environment:JAVA_OPTS                            | Text      |                                  | See below                                                                         |
| services:jenkins:environment:JENKINS_USERNAME                     | Text      | Your username                    |                                                                                   |
| services:jenkins:environment:JENKINS_PASSWORD                     | Sensitve  | Your password                    |                                                                                   |
| services:jenkins:image                                            | Text      | docker.io/bitnami/jenkins:#{Project.Jenkins.ServerTag} |                                                             |
| services:jenkins:ports:0                                          | Text      | #{Project.Jenkins.Port}:8080     |                                                                                   |

#### JAVA_OPTS

If you plan to use this Jenkins server with another locally hosted service, like [octopus.local](https://github.com/OctopusDeployLabs/octopus.local), you will need to add the other service's certificates to the Java keystore.

After doing that, it's recommended to move the keystore to the `jenkins_home` folder. Then change your JAVA_OPTS variable above to:

```
-Djavax.net.ssl.trustStore=/var/jenkins_home/cacerts -Djavax.net.ssl.trustStorePassword=#{Project.Jenkins.TrustStorePassword}
```

`changeit` is the default password to the keystore in the docker image. It is recommended to change the password and store that as `Project.Jenkins.TrustStorePassword`.

### Project Deployment Process

Navigate to **Deployments > Process**. Click **Add Step** and add a **Deploy a Package** step.

Click on **Configure Features** and choose only **Customer Installation Directory**, **Structured Configuration Variables**, and **Substitute Variables in Templates**.

Choose the target role that you assigned to your Linux server target.

Choose your GitHub package feed and enter `OctopusDeployLabs/jenkins.local` as the package ID.

Set the **Custom Install Directory** to `#{Project.Jenkins.InstallLocation}`.

Set the **Structured Configuration Variables Target Files** to `docker-compose.yml`.

Set the **Substitute Variables in Templates Target Files** to `jenkins.local` and `jenkins-local.service`. These entries must be separated by a new line character.

## Files

### docker-compose.yml

This is a file based on [Bitnami's docker-compose file](https://github.com/bitnami/bitnami-docker-jenkins).

### jenkins-local.service

This file configures a systemd service to control the Jenkins instance and also ensures that it starts when the server boots.

You can stop the Jenkins service with:

```
sudo systemctl stop jenkins-local
```

And start it with :

```
sudo systemctl start jenkins-local
```

### jenkins.local site configuration

This is the Nginx site configuration. SSL is enabled, and you need to provide the certificate and key location as variables in the deployment process.

The configuration uses `jenkins.local` as the host name. You will need to configure your local DNS server or hosts files to route `jenkins.local` to the server hosting this service.

### predeploy.sh

This script creates a user `jenkins` with id 1001 to match the user used by the Jenkins container. The local volumes are owned by this user so that the Jenkins container can access them.

### deploy.sh

This script creates or updates the Docker containers, systemd service, and Nginx site.

## Disclaimer

No warranty expressed or implied. Code is provided as is.
