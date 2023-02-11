FROM alpine:3.17.1

RUN adduser worker -h /home/worker -D && \
    echo -n worker:password | chpasswd && \ 
    apk add openssh rsync R R-dev build-base linux-headers perl && \
    ssh-keygen -A && \
    Rscript -e 'install.packages(c("qs", "readr"), repos="https://cran.rstudio.com")'

WORKDIR /home/worker

COPY ./id_rsa_test.pub .ssh/authorized_keys
COPY ./exec_task.R .
COPY ./collect_metadata.R .
COPY ./exec_task_and_collect_metadata.sh .

EXPOSE 22

ENTRYPOINT [ "/usr/sbin/sshd", "-D", "-e" ]
