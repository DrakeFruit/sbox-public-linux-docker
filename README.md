# sbox-public-linux-docker
Dockerized s&box linux engine.

## Usage
```bash
# Build Docker Image
docker build -t tsktp/sbox-public-linux-docker:latest .

# Latest Public Build
docker run tsktp/sbox-public-linux-docker:latest
```

## Steps

### Building
```bash
git clone https://github.com/tsktp/sbox-public-linux-docker.git
cd sbox-public-linux-docker
docker build -t tsktp/sbox-public-linux-docker:latest .
```

### Accessing Data and Running
```bash
docker create ${volume_name}
docker run -it -v ${volume_name}:/root/sbox tsktp/sbox-public-linux-docker:latest

# locate volume location
docker volume inspect ${volume_name}

# list directory
ls -la /var/lib/docker/volumes/{volume_name}/_data
```

