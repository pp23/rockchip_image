# Makefile

# === Configuration ===
REPO_URL ?= https://gitlab.com/buildroot.org/buildroot.git
BRANCH   ?= 2025.08
TMP_DIR  := $(shell mktemp -d)

# === Targets ===
.PHONY: all clone run clean

all: run

# Clone the repository into TMP_DIR
clone:
	@echo "Cloning $(REPO_URL) into $(TMP_DIR)..."
	git clone --branch $(BRANCH) --depth 1 $(REPO_URL) $(TMP_DIR)
	@echo "Repository cloned into: $(TMP_DIR)"

# Run the cloned repo's Makefile
run: clone
	@echo "Running Makefile from cloned repository..."
	$(MAKE) -C $(TMP_DIR)

# Optional: clean up
clean:
	@if [ -d "$(TMP_DIR)" ]; then \
		echo "Removing temporary directory $(TMP_DIR)"; \
		rm -rf "$(TMP_DIR)"; \
	else \
		echo "No temporary directory to remove."; \
	fi
