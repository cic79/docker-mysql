# DOCKER

## Remove old versions
```
sudo apt purge docker docker-engine
```


## Install dependencies
```
sudo apt install linux-image-extra-$(uname -r) linux-image-extra-virtual apt-transport-https ca-certificates curl software-properties-common
```


## Add repository
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```


## Install docker-ce
```
sudo apt update; sudo apt install docker-ce
```


## Run as non-root
```
sudo groupadd docker
sudo usermod -aG docker $USER
```


### Log out and log back in (oppure eseguire: exec su -l $USER)
```
docker run hello-world
```


## Docker Compose
```
sudo curl -L "`curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep "$(uname -s)-$(uname -m)" | grep -i -v sha256 | awk '/browser_download_url/ { print $2 }' | sed 's/"//g'`" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```


### Docker Compose command-line completion
```
sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
```


### Check compatibility (optional don't do this)
```
curl https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh > check-config.sh
bash ./check-config.sh
```

Output:

```
# - CONFIG_MEMCG_SWAP_ENABLED: missing
?
# - CONFIG_RT_GROUP_SCHED: missing
?
#   - "zfs":
#     - /dev/zfs: missing
#     - zfs command: missing
#     - zpool command: missing
```
```
sudo apt install zfsutils-linux
```


## Change docker directory

### Stop docker service
```
sudo service docker stop
```

Instead of modifying the systemd startup script, one can modify the "-g / --graph" option by adding a
/etc/docker/daemon.json with the contents of:

```
{
"graph": "/new/path/docker"
}
```

### Start docker service
```
sudo service docker start
```


## STARTUP THE PROJECT

### Build or rebuild services
```
docker-compose build
```


### Create and start containers
```
docker-compose up -d
```


## USEFULL COMMANDS


### List containers
```
docker-compose ps
```

### Run the command 'bash' in a running container
Connect to the bash inside container named CONTAINER

```
docker exec -it CONTAINER bash
```


### Stop container
```
docker-compose stop
docker-compose stop <container>
```


### Logs
```
docker-compose logs
docker-compose logs <service> (es. docker logs django)
docker logs -f --tail=10 <service>
docker-compose logs -f --tail=10 <service> (service is optional)
```


### Docker images
```
docker images
docker rmi <IMAGE_ID>
docker rmi -f <IMAGE_ID>
```


### Delete all containers
```
docker rm $(docker ps -a -q)
```


### Delete all images
```
docker rmi $(docker images -q)
```


### Delete docker non tagged-images
```
docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
```


### Remove all SAVE dirs created from project root
```
find . -name SAVE -exec rm -rf {} \;
```

This will remove: all stopped containers, all volumes not used by at least one container
all networks not used by at least one container, all dangling images

```
docker system prune
docker system prune -a -f (To delete all images)
```


### Remove all images used by the docker-compose service:

```
docker-compose down --rmi all
```


### Remove only images that don't have a custom tag

``` 
docker-compose down --rmi local
```


## CEREBRO

To check the status of the elasticsearch cluster and to send REST call go to:

Uncomment the cerebro section in the docker-compose.yml and restart the cluster then go to:

```
http://127.0.0.1:9212/#/overview?host=http:%2F%2Felasticsearch1:9200
```


## BRIDGE SUBNET

To set bridge subnet:
```
sudo vim /etc/docker/daemon.json
```
it should looked like this (last row if vpn is not working):
```
{
  "bip": "192.0.0.1/24",
  "dns": ["10.0.0.2", "8.8.8.8"]
}
```

## COMMON ERRORS

### max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

Set the value `vm.max_map_count = 262144` at the end of the file:
```
sudo vim /etc/sysctl.conf
```

then launch this command for a live update of this value:
```
sudo sysctl -w vm.max_map_count=262144
```
