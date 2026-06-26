# A deliberately different, tiny app (xterm) to prove the appliance is app-agnostic:
# swapping the boot-folder compose runs a different app with no change to the
# security machinery.
FROM jlesage/baseimage-gui:debian-12-v4.12.5
RUN add-pkg xterm
RUN set-cont-env APP_NAME "Xterm"
COPY startapp.sh /startapp.sh
RUN chmod +x /startapp.sh
