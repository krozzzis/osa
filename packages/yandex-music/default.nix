{
  lib,
  buildPythonPackage,
  fetchurl,
  hatchling,
  requests,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "yandex-music";
  version = "3.2.2";
  format = "pyproject";

  # The sdist is published as yandex_music-<version>.tar.gz, which
  # fetchPypi's name-derived URL cannot express.
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/fe/a0/69ea55bdff91f2e4a996d08ce89402e56be46a6c7a9ac5d9a9c5e76436ee/yandex_music-${version}.tar.gz";
    hash = "sha256-6wtCQFIc4tBP/4dsna2n7OZUWTeZe6Eg/PqoE++CVrI=";
  };

  # The [build-system] backend is not inferred, so name it explicitly.
  nativeBuildInputs = [ hatchling ];

  # Upstream's optional extras (ynison, orjson, ...) are unused by the
  # cloudmus backend, and its test suite is not shipped in the sdist.
  propagatedBuildInputs = [
    requests
    typing-extensions
  ];

  pythonImportsCheck = [ "yandex_music" ];

  meta = {
    description = "Unofficial Python library for the Yandex Music API";
    homepage = "https://github.com/MarshalX/yandex-music-api";
    license = lib.licenses.lgpl3Only;
  };
}
