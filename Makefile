.PHONY: run-dev run-local run-prod build-dev build-prod get clean

run-dev:
	flutter run --flavor dev --dart-define-from-file=assets/env/app.dev.env

run-local:
	flutter run --flavor local --dart-define-from-file=assets/env/app.local.env

run-prod:
	flutter run --flavor prod --dart-define-from-file=assets/env/app.prod.env --release

build-dev:
	flutter build apk --flavor dev --dart-define-from-file=assets/env/app.dev.env

build-prod:
	flutter build apk --flavor prod --dart-define-from-file=assets/env/app.prod.env --release --obfuscate --split-debug-info=build/symbols/

get:
	flutter pub get

clean:
	flutter clean && flutter pub get
