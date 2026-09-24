.PHONY: dependency lint template test verify

dependency:
	helm dependency update tests
	helm dependency update tests/extras

lint: dependency
	helm lint --strict tests
	helm lint --strict tests/extras

template: dependency
	helm template contoso tests >/dev/null
	helm template contoso-extras tests/extras >/dev/null

test: dependency
	helm unittest --strict --file 'tests/tests/*_test.yaml' tests
	helm unittest --strict --file 'tests/extras/tests/*_test.yaml' tests/extras

verify: lint template test
