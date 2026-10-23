{
  lib,
  stdenv,
  curl,
  cacert,
}:

let
  data = builtins.fromJSON (builtins.readFile ./version.json);
  system = stdenv.hostPlatform.system;

  asset =
    {
      x86_64-linux = "cypher-language-server-linux-x86_64";
    }
    .${system} or (throw "cypher-language-server: no release bundle for ${system}");

  url = "https://github.com/atomic-235/cypher-language-server-flake/releases/download/v${data.version}/${asset}";

  # Self-extracting bundle (arx) with node + node_modules + dist, so it runs
  # without /nix/store. Nix refuses fixed-output paths whose contents mention
  # store paths, hence the waiver.
  bundle = stdenv.mkDerivation {
    name = "cypher-language-server-${data.version}-${asset}";

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = data.assets.${system};
    unsafeDiscardReferences = true;

    nativeBuildInputs = [ curl ];

    buildCommand = ''
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
      curl -fsSL --cacert "$SSL_CERT_FILE" -o "$out" ${lib.escapeShellArg url}
    '';
  };
in
stdenv.mkDerivation {
  pname = "cypher-language-server";
  version = data.version;

  src = bundle;
  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/cypher-language-server"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Neo4j/openCypher language server, self-contained release bundle";
    homepage = "https://github.com/neo4j/cypher-language-support";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cypher-language-server";
  };
}
