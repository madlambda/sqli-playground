.PHONY: default
default: help

DOCKER_DBIMAGE=mysql:8.0.28
DOCKER_DBCNT=mysqlinjection
DOCKER_DBNAME=sqli
DOCKER_DBUSER=root
DOCKER_DBPASS=123456
DOCKER_DBHOST=0.0.0.0
DOCKER_DBPORT=3306
DOCKER_DBADDR=$(DOCKER_DBHOST):$(DOCKER_DBPORT)

ASROOT=sudo
ifeq (, $(shell which $(ASROOT) 2>/dev/null))
ASROOT=doas
endif


.PHONY: db
db: ## Start db
	-$(ASROOT) docker rm -vf $(DOCKER_DBCNT)
	$(ASROOT) docker run --rm --name $(DOCKER_DBCNT)                           \
		--net host                                                             \
		-e MYSQL_ROOT_PASSWORD=$(DOCKER_DBPASS)                                \
		-e MYSQL_DATABASE=$(DOCKER_DBNAME)                                     \
        -d $(DOCKER_DBIMAGE)
	# check if database is ready
	@while !(make dbtest 2>/dev/null 1>/dev/null); do echo -n "."; sleep 1; done

	$(ASROOT) docker run -i --net host --rm $(DOCKER_DBIMAGE) mysql            \
		-h $(DOCKER_DBHOST) -u$(DOCKER_DBUSER) -p$(DOCKER_DBPASS)              \
		-D $(DOCKER_DBNAME) < populate.sql


.PHONY:dbcli
dbcli: ## connects and retrieves a database a shell.
	@docker run -it --net host --rm mysql mysql -h $(DOCKER_DBHOST)            \
		-u$(DOCKER_DBUSER) -p$(DOCKER_DBPASS) -D $(DOCKER_DBNAME)


.PHONY: dbtest
dbtest: ## test db connectivity
	@docker run -it --net host --rm mysql mysql -h $(DOCKER_DBHOST)            \
		-u$(DOCKER_DBUSER) -p$(DOCKER_DBPASS) -D $(DOCKER_DBNAME)              \
		-e "show status;" >/dev/null


.PHONY: build
build: ## build sqli
	go build -o ./sqli-play


.PHONY: up
up: db run ## build, setup db and start sqli service.


.PHONY: run
run: build ## run
	@DBNAME=$(DOCKER_DBNAME)                                                   \
	DBUSER=$(DOCKER_DBUSER)                                                    \
	DBPASS=$(DOCKER_DBPASS)                                                    \
	DBADDR=$(DOCKER_DBADDR)                                                    \
	./sqli-play


.PHONY: help
help: ## Show this help message.
	@echo "usage: make [target] ..."
	@echo
	@echo -e "targets:"
	@egrep '.*?:.*?## [^$$]*?$$' ${MAKEFILE_LIST} |                            \
		sed -r 's/(.*?):\ .*?\#\# (.+?)/\1:\t\2/g'
