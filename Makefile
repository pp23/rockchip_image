# Makefile

# === Configuration ===
REPO_URL ?= https://gitlab.com/buildroot.org/buildroot.git
BRANCH   ?= 2025.08
TMP_DIR  := $(shell mktemp -d)
BUILD_DIR  ?= $(TMP_DIR)
COMMIT_HASH ?= 3386677f0a4d1c0150e772eb07cede05e88a2d6d
BR_CONFIG ?= config.buildroot.orangepi5plus

# === Targets ===
.PHONY: all clone verify run clean

all: run

# 1. Clone repository
clone:
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "Build dir \"$(BUILD_DIR)\" is not empty. Skipping cloning the buildroot-repo"; \
	else \
		@echo "Cloning $(REPO_URL) (branch: $(BRANCH)) into $(BUILD_DIR)..."; \
		git clone --branch $(BRANCH) --depth 1 $(REPO_URL) $(BUILD_DIR) >/dev/null; \
		@echo "Repository cloned successfully into: $(BUILD_DIR)"; \
	fi

# 2.1 Verify commit hash
verify: clone
	@cd $(BUILD_DIR) && \
	ACTUAL_HASH=$$(git rev-parse HEAD); \
	echo "Verifying commit hash..."; \
	echo "  Expected: $(COMMIT_HASH) (ref: $(BRANCH))"; \
	echo "  Actual:   $$ACTUAL_HASH"; \
	if [ "$$ACTUAL_HASH" != "$(COMMIT_HASH)" ]; then \
		echo "❌ Commit hash mismatch!"; \
		exit 1; \
	else \
		echo "✅ Commit hash verified."; \
	fi

# 2.2 Copy buildroot config
copy-buildroot-cfg: clone
	@cp -i $(BR_CONFIG) $(BUILD_DIR)/.config # -i: ask before overwriting existing files


# 2.3 Download packages
download-pkgs: verify copy-buildroot-cfg
	@cd $(BUILD_DIR) && \
	unset LD_LIBRARY_PATH; $(MAKE) source

# 3. Run cloned repo's Makefile only if verified
run: verify copy-buildroot-cfg
	@echo "Running cloned repository Makefile..."
	unset LD_LIBRARY_PATH; make -C $(BUILD_DIR)

# 4. Optional cleanup
clean:
	@if [ -d "$(BUILD_DIR)" ]; then \
		echo "Removing temporary directory $(BUILD_DIR)"; \
		rm -rf "$(BUILD_DIR)"; \
	else \
		echo "No temporary directory to remove."; \
	fi

