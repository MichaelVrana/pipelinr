FROM alpine:3.17.1

RUN adduser worker -h /home/worker -D && \
    echo -n worker:password | chpasswd && \ 
    apk add openssh rsync R R-dev build-base linux-headers perl && \
    ssh-keygen -A && \
    Rscript -e 'install.packages("qs", repos="https://cran.rstudio.com")'

COPY ./id_rsa_test.pub /home/worker/.ssh/authorized_keys
COPY ./exec_task.R /home/worker

EXPOSE 22

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]
