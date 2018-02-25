# Simulator OpenFoam

### Installation

Create an ssh key pair for connecting to the container:

```bash
ssh-keygen -t rsa -f simulator_key -C "Key for simulator Docker container" -N ''
export SIMULATOR_KEY_PUBLIC=$(cat simulator_key.pub)
```

Build and run the container:

```bash
docker build -t simulator_base .
docker run -d --privileged -e AUTHORIZED_KEY="$SIMULATOR_KEY_PUBLIC" -p 10022:22 simulator_base
```

Connect via ssh:

```bash
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i simulator_key -p 10022 testuser@localhost
```
