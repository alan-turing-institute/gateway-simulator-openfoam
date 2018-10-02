FROM phusion/baseimage:0.9.19
MAINTAINER Lachlan Mason <l.mason@imperial.ac.uk>

# Install required packages
RUN apt-get update \
    && apt-get install -y \
    python-setuptools \
    torque-scheduler \
    torque-server \
    torque-mom \
    torque-client \
    wget \
    bzip2 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean all

# install pip
# RUN easy_install pip

# Enable ssh, see following link for ssh documentation
# https://github.com/phusion/baseimage-docker#login-to-the-container-or-running-a-command-inside-it-via-ssh
RUN rm -f /etc/service/sshd/down && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config

RUN mkdir -p /etc/my_init.d
COPY ./scripts/setup-hostnames.sh /etc/my_init.d/01_setup-hostnames.sh

# This must coincide with the value set in scripts/setup-hostnames.sh
ENV HOSTNAME simulator

# Set the hostname by hand in the various configuration files
RUN echo "$HOSTNAME" > /etc/torque/server_name && \
    echo '$pbsserver '"$HOSTNAME" > /var/spool/torque/mom_priv/config && \
    echo "$HOSTNAME np=1" > /var/spool/torque/server_priv/nodes

# Start the service to allow reconfiguration and configure it. On the same line
# to avoid caching and to have the service up in the container, otherwise it
# shuts down. It is also needed to run the setup-hostnames.sh script to
# rewrite/reset the /etc/hosts (this is needed by torque)
RUN /etc/my_init.d/01_setup-hostnames.sh && \
    /etc/init.d/torque-server start && \
    /etc/init.d/torque-mom start && \
    /etc/init.d/torque-scheduler start && \
    echo "Waiting 5 seconds to make sure the service starts..." && \
    sleep 5 && \
    qmgr -c "create queue batch queue_type=execution" && \
    qmgr -c "set server query_other_jobs = True" && \
    qmgr -c "set queue batch resources_max.ncpus=1" && \
    qmgr -c "set server default_queue=batch" && \
    echo "* Torque queue set" && \
    qmgr -c "set queue batch enabled=True" && \
    qmgr -c "set queue batch started=True" && \
    echo "* Torque queue started" && \
    qmgr -c "set queue batch resources_default.nodes=1" && \
    qmgr -c "set queue batch resources_default.walltime=3600" && \
    qmgr -c "set queue batch max_running=1" && \
    echo "* Torque queue parameters set" && \
    qmgr -c "set server scheduling=True" && \
    echo "* Torque scheduling started" && \
    qmgr -c "unset server acl_hosts" && \
    qmgr -c "set server acl_hosts=$HOSTNAME" && \
    echo "* Torque server ACL hosts set"

## If the user 'root' should be allowed to submit, add also the next line
#    qmgr -c 's s acl_roots+=root@*' && \
#    echo "User 'root' now allowed to submit"

## TODO: potentially decide if you want this to be a volume
## You can do this also when running the container
RUN mkdir /scratch

# Expose SSH port
EXPOSE 22

# create an empty authorized_keys for user 'testuser', give right permissions
RUN useradd --create-home --home /home/testuser \
      --shell /bin/bash testuser && \
    usermod -L testuser && \
    chown testuser:testuser /scratch && \
    mkdir /home/testuser/.ssh && \
    touch /home/testuser/.ssh/authorized_keys && \
    chown -R testuser:testuser /home/testuser/.ssh && \
    chmod -R go= /home/testuser/.ssh

## Put the script for the initial setup of the authorized_keys of the
## testuser user
COPY ./scripts/init_authorized_keys.sh /etc/my_init.d/init_authorized_keys.sh

# So that supervisord log files go in /root and are not visible
WORKDIR /root

## Start services (torque)
RUN mkdir -p /etc/service/torque_server && \
    mkdir -p /etc/service/torque_mom_scheduler

COPY ./scripts/torque_server_run.sh /etc/service/torque_server/run
COPY ./scripts/torque_mom_scheduler_run.sh /etc/service/torque_mom_scheduler/run

# openfoam dependencies
RUN wget -O - http://dl.openfoam.org/gpg.key | apt-key add - \
    && add-apt-repository http://dl.openfoam.org/ubuntu \
    && apt-get update \
    && apt-get -y install openfoam5
RUN echo ". /opt/openfoam5/etc/bashrc" >> /home/testuser/.bashrc

RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# setting `USER testuser` for the following lines breaks docker build on Azure VM
ADD requirements.txt /home/testuser/
RUN chown -R testuser:testuser /home/testuser/requirements.txt
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/testuser/.bashrc && \
    echo "conda activate base" >> /home/testuser/.bashrc

USER root

# install python 3 environment as "base"
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate base && \
    /opt/conda/bin/pip install -r /home/testuser/requirements.txt

# install python 2.7 environment as "ml"
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda create --name ml python=2.7 && \
    conda activate ml && \
    /opt/conda/envs/ml/bin/pip install -r /home/testuser/requirements.txt

RUN apt-get install -y git libxcursor-dev libxft-dev libxinerama-dev

# install gmsh from web
WORKDIR /tmp
RUN mkdir /opt/gmsh && \
    cd /opt/gmsh && \
    wget http://gmsh.info/bin/Linux/gmsh-3.0.6-Linux64.tgz && \
    tar -xvzf gmsh-3.0.6-Linux64.tgz && \
    ln -s /opt/gmsh/gmsh-3.0.6-Linux64/bin/gmsh /usr/bin/gmsh 