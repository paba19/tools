# Tooling docker images

## Build the images

First build the base image

`sudo docker build --tag platform-base -f ./platform-base  .`

Then build the the local dev image

`sudo docker build --tag platform-local-dev -f ./platform-local-dev  .`

## Run the images

### Actions on host 

Because a non root user is used in the docker container, you need to give access to that user id to the directories that are shared.

`setfacl -m g:1001:rwx ~/.ssh`
`setfacl -m g:1001:rwx ~/.aws`
(if a config file already exists in your ~/.aws directory) `setfacl -m g:1001:rw ~/.aws/config`
(if a profile file already exists in your ~/.aws directory) `setfacl -m g:1001:rw ~/.aws/profile`
(if a credentials file already exists in your ~/.aws directory) `setfacl -m g:1001:rw ~/.aws/credentials`
`setfacl -m g:1001:rwx ~/.kube`
(if a config file already exists in your ~/.kube directory) `setfacl -m g:1001:rw ~/.kube/config`

### Run the container

`sudo docker run -ti --rm --name local-dev -v /home/$(id -u)/.aws:/home/dev/.aws -v /home/$(id -u)/.ssh:/home/dev/.ssh -v /home/$(id -u)/.kube:/home/dev/.kube platform-local-dev zsh`


# Use the script
You can also use the script build.sh

It will go through all the directories.

The idea is to build a common base, and then a terraform and a pulumi local dev, so you can use one or the other