#DOCKER_REPOSITORY ?= freelawproject/solr
#
#DOCKER ?= docker
#export DOCKER
#
#DOCKER_TAG = 0.21
#
#all: image
#
#image:
#    $(DOCKER) buildx build --platform linux/amd64,linux/arm64 --tag=$(DOCKER_REPOSITORY):$(DOCKER_TAG) --tag=$(DOCKER_REPOSITORY):latest . --no-cache
#    $(DOCKER) buildx build --cache-from=type=local,src=cache --load  --tag=$(DOCKER_REPOSITORY):$(DOCKER_TAG) --tag=$(DOCKER_REPOSITORY):latest .
#
#push: image
#	$(DOCKER) buildx build --push --platform linux/amd64,linux/arm64 -t $(DOCKER_REPOSITORY):latest -t $(DOCKER_REPOSITORY):$(DOCKER_TAG) .


# Run with make push --file docker/django/Makefile
DOCKER_REPOSITORY ?= freelawproject/solr

DOCKER ?= docker
export DOCKER

DOCKER_TAG = "0.21"

.PHONY: all image push

all: image

image:
	$(DOCKER) buildx build --platform linux/amd64,linux/arm64 -t $(DOCKER_REPOSITORY):latest -t $(DOCKER_REPOSITORY):$(DOCKER_TAG) .
	$(DOCKER) buildx build --cache-from=type=local,src=cache -t $(DOCKER_REPOSITORY):latest -t $(DOCKER_REPOSITORY):$(DOCKER_TAG) --load .

push: image
	$(DOCKER) buildx build --push --platform linux/amd64,linux/arm64 -t $(DOCKER_REPOSITORY):latest -t $(DOCKER_REPOSITORY):$(DOCKER_TAG) .
