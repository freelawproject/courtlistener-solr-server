# Docker Image for Solr v4

This is a docker image that we forked from https://github.com/2degrees/docker-solr4. The original is really good, but this fork has all of our fun customizations. 

In theory, this fork should be very easy to use. In order to set up a working
solr install, simply:

1. Install Docker

1. Create a directory on the host machine to store solr indicies, or select the
   one you have already. Then, add that directory to group ID 1024 and set make
   the group ID apply to new directories too:
   
       chown -R :1024 /data/myvolume
       find /data/myvolume -type d -exec chmod g+s {} \;
       
   Change the permissions of the directory to allow the group the access it 
   needs to directories and files respectively:
   
       find /data/myvolume -type d -exec chmod 775 {} \;
       find /data/myvolume -type f -exec chmod 664 {} \;
       
   Optionally, on a dev machine say, add your username to this group too, so 
   you can access the files:  
   
       usermod -a -G 1024 my-username
       
    [Approach adapted from the link here](https://medium.com/@nielssj/docker-volumes-and-file-system-permissions-772c1aee23ca).

1. Run this:

         docker run  \
             --memory 100g \
             --cpus 32 \
             --volume /home/username/projects/courtlistener-solr-server/solr/cores:/etc/opt/solr:ro \
             --volume /home/username/projects/data/courtlistener/solr:/var/opt/solr/indices \
             -p 127.0.0.1:8983:8983 \
             --log-driver journald \
             --name solr \
             freelawproject/solr 

Some explanation is in order:

1. `--memory` and `--cpus`, perhaps obviously, can be tweaked as needed or 
omitted if you prefer. These command constrain how many resources the image is 
allowed.

1. The `--volume` commands mount two directories from the host machine to the 
container. The first, which is mounted read only (`ro`), tells Solr where to 
find configuration files. This mapping should be from this repository to the 
directory shown above. 

    The second maps the local index directory to the index directory in the 
    container. If you already have indices (ie, this is an upgrade from our old
    system), this should be the parent of your current indices directories. 
    If this is an upgrade, the index directories should match the name of the 
    core configuration directories (at present, this is audio, collection1, 
    person, & recap).

1. Next we map the local port to the container port.

1. `--log-driver journald` sends stdout and stderr to journalctl.

1. `--name solr` gives it a name (so we can see it in our logs, among other
   reasons).

1. Finally, we list the name of the image to download (if needed) and run.


## Viewing logs

The command above advises using journald for the logs. To view the logs, run:

    journalctl -f CONTAINER_NAME=solr
    
If that doesn't work, it's probably because the name of the container changed
somehow. Figure out the correct name by using:

    docker container ls
    
And look at the NAME column.


## Adding Cores

Solr can auto-discover cores anywhere in its home directory, but the `cores`
sub-directory is recommended.

The `example` directory in the Solr distribution is preserved in case you want
to configure your core(s) dynamically using any file in there. For example,
you may want to copy `solrconfig.xml` and alter the copy in-place (with `patch`
or `sed`, for example), instead of maintaining a modified copy of the whole
file.

You are able to mount the core directories in read-only mode, as the indices
are kept outside.


## Relevant Directories

If you need to refer to any of the paths below, use the corresponding
environment variable where possible.

- Solr Home (`${SOLR_HOME_PATH}`): `/etc/opt/solr`
- Solr Distribution (`${SOLR_DISTRIBUTION_PATH}`): `/opt/solr`
- Jetty Home (`${JETTY_HOME_PATH}`): `/etc/opt/jetty`
- Solr indices (`${SOLR_INDICES_DIR_PATH}`): `/var/opt/solr/indices`


## The `solr.sh` Command

This is the default command, and it runs the web server in the foreground with
some default, run-time arguments for the Java VM, Jetty and Solr. Any additional
arguments to this script, such as property definitions, will be passed on to
the JVM.

If you place any limit on the memory for the container, the JVM's heap memory
will be configured accordingly so that you only have to manage memory
allocation from Docker. To enable this, just add the `--memory=X` option to
`docker run` or the equivalent in Docker Compose.

This script is meant as a replacement for `${SOLR_DISTRIBUTION_PATH}/bin/solr`
because the latter does not propagate signals (e.g., `SIGTERM`) to the JVM,
meaning that `docker stop` wouldn't actually stop the container.

