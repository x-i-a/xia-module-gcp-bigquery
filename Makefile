.PHONY: all init create

all:
	@echo "Specify a command to run"

init:
	python3 -m venv .venv; \
	until [ -f .venv/bin/python3 ]; do sleep 1; done; \
	until [ -f .venv/bin/activate ]; do sleep 1; done;
	. .venv/bin/activate; \
	pip install PyYAML xia-framework keyring setuptools wheel; \
    pip install keyrings.google-artifactregistry-auth; \

create: init
	@. .venv/bin/activate; \
	python main.py prepare