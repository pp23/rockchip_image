# Makefile

# === Configuration ===
REPO_URL ?= https://gitlab.com/buildroot.org/buildroot.git
BRANCH   ?= 2025.08
TMP_DIR  := $(shell mktemp -d)
COMMIT_HASH ?= 3386677f0a4d1c0150e772eb07cede05e88a2d6d
BR_CONFIG ?= config.buildroot.orangepi5plus

# === Targets ===
.PHONY: all clone verify run clean

all: run

# 1. Clone repository
clone:
	@echo "Cloning $(REPO_URL) (branch: $(BRANCH)) into $(TMP_DIR)..."
	git clone --branch $(BRANCH) --depth 1 $(REPO_URL) $(TMP_DIR) >/dev/null
	@echo "Repository cloned successfully into: $(TMP_DIR)"

# 2.1 Verify commit hash
verify: clone
	@cd $(TMP_DIR) && \
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
	@cp  $(BR_CONFIG) $(TMP_DIR)/.config


# 2.3 Download packages
download-pkgs: verify copy-buildroot-cfg
	@cd $(TMP_DIR) && \
	$(MAKE) source

# 3. Run cloned repo's Makefile only if verified
run: verify copy-buildroot-cfg
	@echo "Running cloned repository Makefile..."
	$(MAKE) PATH="$(PWD)/debug_tools:$(PATH)" -C $(TMP_DIR)

# 4. Optional cleanup
clean:
	@if [ -d "$(TMP_DIR)" ]; then \
		echo "Removing temporary directory $(TMP_DIR)"; \
		rm -rf "$(TMP_DIR)"; \
	else \
		echo "No temporary directory to remove."; \
	fi

