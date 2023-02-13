GO ?= $(shell which go)
OS ?= $(shell $(GO) env GOOS)
ARCH ?= $(shell $(GO) env GOARCH)

IMAGE_NAME := "sintef/cert-manager-gandi"
IMAGE_TAG := "0.4.0"

OUT := $(shell pwd)/_out

KUBE_VERSION=1.25.0

$(shell mkdir -p "$(OUT)")
export TEST_ASSET_ETCD=_test/kubebuilder/etcd
export TEST_ASSET_KUBE_APISERVER=_test/kubebuilder/kube-apiserver
export TEST_ASSET_KUBECTL=_test/kubebuilder/kubectl

test: _test/kubebuilder
	$(GO) test -v .

_test/kubebuilder:
	curl -fsSL https://go.kubebuilder.io/test-tools/$(KUBE_VERSION)/$(OS)/$(ARCH) -o kubebuilder-tools.tar.gz
	mkdir -p _test/kubebuilder
	tar -xvf kubebuilder-tools.tar.gz
	mv kubebuilder/bin/* _test/kubebuilder/
	rm kubebuilder-tools.tar.gz
	rm -R kubebuilder

clean: clean-kubebuilder

clean-kubebuilder:
	rm -Rf _test/kubebuilder

build:
	docker buildx build --target=image --platform=linux/amd64 --output=type=docker,name=${IMAGE_NAME}:${IMAGE_TAG} --tag=${IMAGE_NAME}:latest --build-arg=GO_VERSION=${GO_VERSION} .

package:
	helm package deploy/cert-manager-webhook-gandi -d charts/
	helm repo index charts/ --url https://bwolf.github.io/cert-manager-webhook-gandi

.PHONY: rendered-manifest.yaml
rendered-manifest.yaml:
	helm template \
        --set image.repository=${IMAGE_NAME} \
        --set image.tag=${IMAGE_TAG} \
        deploy/cert-manager-webhook-gandi > "${OUT}/rendered-manifest.yaml"