# Makefile for allyas
# Run tests, verify, and cleanup

.PHONY: all test test-bash test-zsh test-all verify lint clean help

# Default target
all: verify

# Run tests in default shell (bash)
test:
	@echo "Running tests in bash..."
	@shellspec --shell bash

# Run tests in bash only
test-bash:
	@echo "Running tests in bash..."
	@shellspec --shell bash --format documentation

# Run tests in zsh only
test-zsh:
	@echo "Running tests in zsh..."
	@shellspec --shell zsh --format documentation

# Run tests in both shells
test-all: clean
	@echo "=========================================="
	@echo "Running tests in BASH"
	@echo "=========================================="
	@shellspec --shell bash --format documentation
	@echo ""
	@echo "=========================================="
	@echo "Running tests in ZSH"
	@echo "=========================================="
	@shellspec --shell zsh --format documentation
	@echo ""
	@echo "=========================================="
	@echo "All tests passed in both shells!"
	@echo "=========================================="

# Verify: run tests in both shells and ensure they pass
verify: clean
	@echo "Verifying tests pass in both bash and zsh..."
	@echo ""
	@echo "=== Testing in BASH ==="
	@shellspec --shell bash || (echo "BASH tests failed!" && exit 1)
	@echo ""
	@echo "=== Testing in ZSH ==="
	@shellspec --shell zsh || (echo "ZSH tests failed!" && exit 1)
	@echo ""
	@echo "✓ All tests pass in both bash and zsh"

# Run ShellCheck linting
lint:
	@echo "Running ShellCheck..."
	@shellcheck --shell=bash --severity=warning allyas.sh
	@shellcheck --shell=bash --severity=warning helpers/*.sh
	@echo "✓ ShellCheck passed"

# Clean up test artifacts
clean:
	@echo "Cleaning up test artifacts..."
	@rm -f .shellspec-quick.log
	@rm -rf coverage/
	@rm -f /tmp/llm_analyze.*.* 2>/dev/null || true
	@rm -f /tmp/shellspec_*.txt 2>/dev/null || true
	@echo "✓ Cleanup complete"

# Quick test (uses quick mode for faster iteration)
quick:
	@shellspec --quick

# Run tests with coverage (requires kcov)
coverage:
	@echo "Running tests with coverage..."
	@shellspec --shell bash --kcov
	@echo "Coverage report generated in coverage/"

# Help
help:
	@echo "allyas Makefile targets:"
	@echo ""
	@echo "  make test       - Run tests in bash (default shell)"
	@echo "  make test-bash  - Run tests in bash with detailed output"
	@echo "  make test-zsh   - Run tests in zsh with detailed output"
	@echo "  make test-all   - Run tests in both bash and zsh"
	@echo "  make verify     - Verify tests pass in both shells (CI mode)"
	@echo "  make lint       - Run ShellCheck on all scripts"
	@echo "  make clean      - Remove test artifacts"
	@echo "  make quick      - Quick test run (uses cached results)"
	@echo "  make coverage   - Run tests with coverage (requires kcov)"
	@echo "  make help       - Show this help message"
