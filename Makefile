.PHONY: *
.DEFAULT_GOAL := help

SHELL := /bin/bash

DEVICE ?= fr255
DEVICES := fr255 fr255m fr255s fr255sm

TOOLCHAIN ?= .toolchain
SDK_DIR ?= $(TOOLCHAIN)/sdk
ifeq ($(shell uname),Darwin)
DEVICES_DIR ?= $(HOME)/Library/Application Support/Garmin/ConnectIQ/Devices
else
DEVICES_DIR ?= $(HOME)/.Garmin/ConnectIQ/Devices
endif
KEY ?= .keys/developer_key.der
MONKEYC = $(SDK_DIR)/bin/monkeyc
DOCKER_IMAGE := token-burn-build

##@ Setup

deps: ## Download the Connect IQ SDK, write any missing device files and create the signing key
	@scripts/install-sdk.sh $(SDK_DIR)
	@$(MAKE) --no-print-directory _devices _key

##@ Development

start: build ## Run the app in the Connect IQ simulator (needs SDK Manager device files)
	@$(MAKE) --no-print-directory _simulate PRG=dist/TokenBurn-$(DEVICE).prg

start/face: build ## Run the watch face in the Connect IQ simulator
	@$(MAKE) --no-print-directory _simulate PRG=dist/TokenBurnFace-$(DEVICE).prg

publish: ## Snapshot plan usage with CodexBar and publish data/usage.json
	@publisher/publish-usage.sh

##@ Testing/Linting

can-release: lint test build/all ## Run every check CI runs

lint: _require_shellcheck ## Lint the publisher and test scripts
	@shellcheck publisher/publish-usage.sh publisher/tests/run.sh scripts/install-sdk.sh video/*.sh

test: ## Run the publisher against the CodexBar fixtures
	@publisher/tests/run.sh

##@ Build

build: _require_sdk ## Build the app and the watch face into dist/ for DEVICE (default fr255)
	@mkdir -p dist
	@$(MONKEYC) -f widget/monkey.jungle -d $(DEVICE) -o dist/TokenBurn-$(DEVICE).prg -y $(KEY) -w -r
	@$(MONKEYC) -f face/monkey.jungle -d $(DEVICE) -o dist/TokenBurnFace-$(DEVICE).prg -y $(KEY) -w -r

build/all: _require_sdk ## Build both for all four Forerunner 255 models
	@for device in $(DEVICES); do $(MAKE) --no-print-directory build DEVICE=$$device || exit 1; done

build/docker: ## Build all four models inside Docker, with no local SDK
	@docker build -t $(DOCKER_IMAGE) -f docker/Dockerfile .
	@docker run --rm -v "$(CURDIR)":/work $(DOCKER_IMAGE)

prebuilt: build ## Copy the fr255 builds into prebuilt/
	@cp dist/TokenBurn-$(DEVICE).prg prebuilt/TokenBurn.prg
	@cp dist/TokenBurnFace-$(DEVICE).prg prebuilt/TokenBurnFace.prg

clean: ## Remove build output
	@rm -rf dist

clean/toolchain: clean ## Remove the downloaded SDK and the signing key
	@rm -rf $(TOOLCHAIN) .keys

##@ Media

video: _require_npm _require_ffmpeg ## Render the parody advert into docs/media/video
	@video/render.sh

video/stock: _require_npm _require_ffmpeg ## Render the stock-footage cut into docs/media/video
	@video/render.sh TokenBurnStock

video/stock-assets: _require_ffmpeg ## Download and prepare the stock clips (not needed to render)
	@python3 video/prepare-stock.py

video/check: _require_npm _require_ffmpeg ## Type-check the edit and check the 40-second music bed
	@cd video && npm ci --no-audit --no-fund --loglevel=error && npx tsc --noEmit
	@video/make-track.sh
	@python3 video/check-track.py

_simulate:
	@$(SDK_DIR)/bin/connectiq &
	@sleep 5
	@$(SDK_DIR)/bin/monkeydo $(PRG) $(DEVICE)

_devices:
	@missing=""; for device in $(DEVICES); do \
		test -f "$(DEVICES_DIR)/$$device/compiler.json" || missing="$$missing $$device"; \
	done; \
	if [ -n "$$missing" ]; then python3 scripts/gen-devices.py --sdk $(SDK_DIR) --out "$(DEVICES_DIR)" $$missing; fi

_key:
	@test -f $(KEY) || ( \
		mkdir -p $(dir $(KEY)) \
		&& openssl genrsa -out $(basename $(KEY)).pem 4096 \
		&& openssl pkcs8 -topk8 -inform PEM -outform DER -in $(basename $(KEY)).pem -out $(KEY) -nocrypt)

_require_sdk:
	@test -x $(MONKEYC) && test -f $(KEY) && test -f "$(DEVICES_DIR)/$(DEVICE)/compiler.json" \
		|| (echo -e "\033[31mERROR: The Connect IQ SDK is not set up. Run 'make deps'.\033[0m" && exit 1)

_require_shellcheck:
	@command -v shellcheck > /dev/null \
		|| (echo -e "\033[31mERROR: shellcheck is not installed. Run 'brew install shellcheck' or 'apt install shellcheck'.\033[0m" && exit 1)

_require_npm:
	@command -v npm > /dev/null \
		|| (echo -e "\033[31mERROR: Node.js is not installed. Run 'brew install node' or install it from nodejs.org.\033[0m" && exit 1)

_require_ffmpeg:
	@command -v ffmpeg > /dev/null \
		|| (echo -e "\033[31mERROR: ffmpeg is not installed. Run 'brew install ffmpeg' or 'apt install ffmpeg'.\033[0m" && exit 1)

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_%\/-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
