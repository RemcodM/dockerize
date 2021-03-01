.SILENT :
.PHONY : dockerize clean fmt

TAG:=`git describe --abbrev=0 --tags`
LDFLAGS:=-X main.buildVersion=$(TAG)

all: dockerize

dockerize:
	echo "Building dockerize"
	go install -ldflags "$(LDFLAGS)"

dist-clean:
	rm -rf dist
	rm -f dockerize-*.tar.gz

dist: dist-clean
	mkdir -p dist/linux/amd64 && GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/linux/amd64/dockerize
	mkdir -p dist/linux/386 && GOOS=linux GOARCH=386 go build -ldflags "$(LDFLAGS)" -o dist/linux/386/dockerize
	mkdir -p dist/linux/armel && GOOS=linux GOARCH=arm GOARM=5 go build -ldflags "$(LDFLAGS)" -o dist/linux/armel/dockerize
	mkdir -p dist/linux/armhf && GOOS=linux GOARCH=arm GOARM=6 go build -ldflags "$(LDFLAGS)" -o dist/linux/armhf/dockerize
	mkdir -p dist/linux/ppc64le && GOOS=linux GOARCH=ppc64le go build -ldflags "$(LDFLAGS)" -o dist/linux/ppc64le/dockerize

release: dist
	tar -cvzf dockerize-linux-amd64-$(TAG).tar.gz -C dist/linux/amd64 dockerize
	tar -cvzf dockerize-linux-386-$(TAG).tar.gz -C dist/linux/386 dockerize
	tar -cvzf dockerize-linux-armel-$(TAG).tar.gz -C dist/linux/armel dockerize
	tar -cvzf dockerize-linux-armhf-$(TAG).tar.gz -C dist/linux/armhf dockerize
	tar -cvzf dockerize-linux-ppc64le-$(TAG).tar.gz -C dist/linux/ppc64le dockerize

push-release: release
	echo -ne "machine github.com\nlogin $$DEPLOY_LOGIN\npassword $$DEPLOY_PASSWORD\n" > ~/.netrc && chmod 600 ~/.netrc
	echo -ne "github.com:\n- user: $$DEPLOY_LOGIN\n  oauth_token: $$DEPLOY_PASSWORD\n  protocol: https\n" > ~/.config/hub
	git config --global --add user.name "Github Actions"
	git config --global --add user.email "github-action@users.noreply.github.com"
	GITHUB_USER=$$DEPLOY_LOGIN GITHUB_TOKEN=$$DEPLOY_PASSWORD GIT_EDITOR=true hub release create \
	    -a dockerize-linux-amd64-$(TAG).tar.gz \
	    -a dockerize-linux-386-$(TAG).tar.gz \
	    -a dockerize-linux-armel-$(TAG).tar.gz \
	    -a dockerize-linux-armhf-$(TAG).tar.gz \
	    -a dockerize-linux-ppc64le-$(TAG).tar.gz \
	    -m "$(TAG)" $(TAG)
