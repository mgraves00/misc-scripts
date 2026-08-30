#

IGNORE_TESTS="SC2148"
SHELL_FILES="ipaddress.lib.sh"

all:
	@echo "Targets:"
	@echo "  check - check SHELL_FILES"

check:
	@for i in "${SHELL_FILES}"; do \
	echo -n "Checking $$i ..."; \
	shellcheck -S error -e "${IGNORE_TESTS}" $$i; \
	echo "done"; \
	done

test:
	./run_tests.sh
