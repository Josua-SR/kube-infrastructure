ARG BASEIMAGE=container.solid-build.xyz/kube/restic-script
FROM ${BASEIMAGE}

COPY sched.sh /sched.sh
ENTRYPOINT ["/bin/sh", "/sched.sh"]
