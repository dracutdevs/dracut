TEST_CASE ?=
BASE_IMAGE ?=

KDUMP_TESTS_LIB ?= $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TEST_OUTPUT ?= $(shell realpath ./)/output
ARCH ?= $(shell arch)

RELEASE ?= 33

DEFAULT_BASE_IMAGE_VER ?= 1.2
DEFAULT_BASE_IMAGE ?= Fedora-Cloud-Base-$(RELEASE)-$(DEFAULT_BASE_IMAGE_VER).$(ARCH).raw.xz
DEFAULT_BASE_IMAGE_URL ?= https://dl.fedoraproject.org/pub/fedora/linux/releases/$(RELEASE)/Cloud/$(ARCH)/images/$(DEFAULT_BASE_IMAGE)


all: $(TEST_OUTPUT)/test-base-image

$(TEST_OUTPUT)/base-image:
	mkdir -p $(TEST_OUTPUT)
ifeq ($(strip $(BASE_IMAGE)),)
	wget -c $(DEFAULT_BASE_IMAGE_URL) -O $(TEST_OUTPUT)/$(DEFAULT_BASE_IMAGE)
	$(KDUMP_TESTS_LIB)/build-image.sh \
		$(TEST_OUTPUT)/$(DEFAULT_BASE_IMAGE)\
		$(TEST_OUTPUT)/base-image
else
	$(KDUMP_TESTS_LIB)/build-image.sh \
		$(BASE_IMAGE)\
		$(TEST_OUTPUT)/base-image
endif

$(TEST_OUTPUT)/inst-base-image: $(TEST_OUTPUT)/base-image
	@echo "Building installation base image"
	$(KDUMP_TESTS_LIB)/build-image.sh \
		$(TEST_OUTPUT)/base-image \
		$(TEST_OUTPUT)/inst-base-image \
		$(KDUMP_TESTS_LIB)/build-scripts/base-image.sh

$(TEST_OUTPUT)/test-base-image_: $(TEST_OUTPUT)/inst-base-image $(EXTRA_RPMS)
	@echo "Building test base image"
	$(KDUMP_TESTS_LIB)/build-image.sh \
		$(TEST_OUTPUT)/inst-base-image \
		$(TEST_OUTPUT)/test-base-image_ \
		$(KDUMP_TESTS_LIB)/build-scripts/test-base-image.sh \
		$(EXTRA_RPMS)

prepare: $(TEST_OUTPUT)/test-base-image_ $(EXTRA_BUILD_SCRIPT) 
	$(KDUMP_TESTS_LIB)/build-image.sh \
		$(TEST_OUTPUT)/test-base-image_ \
		$(TEST_OUTPUT)/test-base-image \
		$(EXTRA_BUILD_SCRIPT)

test-run: prepare
ifeq ($(strip $(TEST_CASE)),)
	$(KDUMP_TESTS_LIB)/run-test.sh
else
	$(KDUMP_TESTS_LIB)/run-test.sh --console $(TEST_CASE)
endif

clean:
	rm -rf $(TEST_OUTPUT)
