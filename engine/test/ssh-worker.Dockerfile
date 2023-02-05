FROM alpine:3.17.1

RUN adduser worker -h /home/worker -D && \
    echo -n worker:password | chpasswd && \ 
    apk add openssh R && \
    ssh-keygen -A 

COPY ./id_rsa_test.pub /home/worker/.ssh/authorized_keys

EXPOSE 22

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]
