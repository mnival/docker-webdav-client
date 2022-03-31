FROM alpine:3.15.2

# Specify URL, username and password to communicate with the remote webdav
# resource. When using _FILE, the password will be read from that file itself,
# which helps passing further passwords using Docker secrets.
ENV WEBDRIVE_URL=
ENV WEBDRIVE_USERNAME=
ENV WEBDRIVE_PASSWORD=
ENV WEBDRIVE_PASSWORD_FILE=

# Location of directory where to mount the drive into the container.
ENV WEBDRIVE_MOUNT=/mnt/webdrive

# In addition, all variables that start with DAVFS2_ will be converted into
# davfs2 compatible options for that share, once the leading DAVFS2_ have been
# removed and once converted to lower case. So, for example, specifying
# DAVFS2_ASK_AUTH=0 will set the davfs2 configuration option ask_auth to 0 for
# that share. See the manual for the list of available options.

RUN set -ex; \
  apk --no-cache add ca-certificates davfs2 tini; \
  printf "user_allow_other\n" >> /etc/fuse.conf; \
  printf "ask_auth 0\n"

COPY *.sh /usr/local/bin/

# The default is to perform all system-level mounting as part of the entrypoint
# to then have a command that will keep listing the files under the main share.
# Listing the files will keep the share active and avoid that the remote server
# closes the connection.
ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/docker-entrypoint.sh" ]
HEALTHCHECK CMD health.sh
