# Makefile for bitcoin

VER = 0.12.1
IMAGE=bitcoin
ARCH=$(shell uname -m)

default: $(IMAGE)-$(VER).tar

Dockerfile.build: df/Dockerfile.build df/Dockerfile.aarch64 df/Dockerfile.armv7l
	cat df/Dockerfile.$(ARCH) df/Dockerfile.build >Dockerfile.build

Dockerfile.run: df/Dockerfile.run df/Dockerfile.aarch64 df/Dockerfile.armv7l
	cat df/Dockerfile.$(ARCH) df/Dockerfile.run >Dockerfile.run

local/deps.txt: Dockerfile.build deps.sh
	docker build --no-cache -t $(ARCH)/$(IMAGE)build:$(VER) -f Dockerfile.build .
	#docker build -t $(IMAGE)build:$(VER) -f Dockerfile.build .
	docker tag -f $(ARCH)/$(IMAGE)build:$(VER) $(ARCH)/$(IMAGE)build:latest
	mkdir -p local
	docker run --rm -it -v $(PWD)/local:/mylocal $(ARCH)/$(IMAGE)build:$(VER) /bin/bash -c "cp -va /usr/local/* /mylocal/"

$(IMAGE)-$(VER).tar: Dockerfile.run local/deps.txt
	docker build --no-cache -t $(ARCH)/$(IMAGE):$(VER) -f Dockerfile.run .
	#docker build -t $(IMAGE):$(VER) -f Dockerfile.run .
	docker tag -f $(ARCH)/$(IMAGE):$(VER) $(ARCH)/$(IMAGE):latest
	docker save -o $(IMAGE)-$(ARCH)-$(VER).tar $(ARCH)/$(IMAGE):$(VER)

clean:
	rm -rf local $(IMAGE)-$(ARCH)-$(VER).tar Dockerfile.build Dockerfile.run

dockerclean:
	docker rmi $(ARCH)/$(IMAGE):latest $(ARCH)/$(IMAGE)build:latest $(ARCH)/$(IMAGE):$(VER) $(ARCH)/$(IMAGE)build:$(VER)

realclean: clean dockerclean

