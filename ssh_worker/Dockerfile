FROM alpine:3.17.1

RUN adduser worker -h /home/worker -D && \
    # A random password is generated for the worker user because it is easier than seting up the Open SSH to allow empty passwords
    # The random password generation is taken from https://unix.stackexchange.com/questions/230673/how-to-generate-a-random-string
    echo -n worker:$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 30) | chpasswd && \
    apk add openssh rsync R R-dev build-base linux-headers perl && \
    ssh-keygen -A && \
    Rscript -e 'install.packages("qs", repos="https://cran.rstudio.com")'

WORKDIR /home/worker

ARG PUB_KEY=./id_rsa.pub

COPY ${PUB_KEY} .ssh/authorized_keys

EXPOSE 22

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]
