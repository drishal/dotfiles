# mnemosyne memory provider, callPackage'd from the hermes interpreter's package set.
# Deps the sealed hermes venv already ships (numpy, onnxruntime, tokenizers, huggingface-hub, pyyaml,
# pillow, requests, tqdm) are dropped: nixpkgs' copies fail the collision check and would shadow them.
{
  buildPythonPackage,
  fetchPypi,
  fastembed,
  loguru,
  mmh3,
  py-rust-stemmers,
  sqlite-vec,
}:
let
  wheel =
    {
      pname,
      version,
      hash,
      dependencies,
    }:
    buildPythonPackage {
      inherit pname version dependencies;
      format = "wheel";
      src = fetchPypi {
        inherit version hash;
        pname = builtins.replaceStrings [ "-" ] [ "_" ] pname;
        format = "wheel";
        dist = "py3";
        python = "py3";
      };
      dontCheckRuntimeDeps = true;
    };

  fastembed' = fastembed.overridePythonAttrs (_: {
    dependencies = [
      loguru
      mmh3
      py-rust-stemmers
    ];
    propagatedBuildInputs = [ ];
    dontCheckRuntimeDeps = true;
    doCheck = false;
    pythonImportsCheck = [ ];
  });

  mnemosyne-memory = wheel {
    pname = "mnemosyne-memory";
    version = "3.15.1";
    hash = "sha256-vHmmJ30hlbulkSMpKSTo/1QhNXxY7lQ6IwVLjdl9dIQ=";
    dependencies = [
      fastembed'
      sqlite-vec
    ];
  };
in
wheel {
  pname = "mnemosyne-hermes";
  # 0.7.x needs mnemosyne-memory 4.0 (beta); 0.5.0 + 3.15.1 wrote the existing database.
  version = "0.5.0";
  hash = "sha256-z6vtLygWxr+ypkBJjLMzjo3r1p4XiqCrYZV2iJljaL8=";
  dependencies = [ mnemosyne-memory ];
}
