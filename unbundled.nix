{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs,
}:

let
  data = builtins.fromJSON (builtins.readFile ./version.json);
in
buildNpmPackage {
  pname = "cypher-language-server";
  version = data.version;

  nativeBuildInputs = [ makeWrapper ];

  # The upstream bin is a symlink to an ESM .js file; a bundle copies the
  # target out of its package directory and Node then parses it as CJS.
  # Ship a shell wrapper instead so the file keeps its package context.
  postInstall = ''
    rm "$out/bin/cypher-language-server"
    makeWrapper ${nodejs}/bin/node "$out/bin/cypher-language-server" \
      --add-flags "$out/lib/node_modules/@neo4j-cypher/language-server/dist/cypher-language-server"
  '';

  # The published npm tarball already ships the built bundle in dist/, so we
  # only need to install its runtime dependencies (npm ci from the lockfile).
  src = fetchurl {
    url = "https://registry.npmjs.org/@neo4j-cypher/language-server/-/language-server-${data.version}.tgz";
    hash = data.integrity;
  };

  sourceRoot = "package";

  # buildNpmPackage runs `npm ci`, which requires a lockfile that the published
  # tarball does not contain; supply one generated from its package.json.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = data.npmDepsHash;

  # dist/ is prebuilt; nothing to compile.
  dontNpmBuild = true;

  meta = with lib; {
    description = "Neo4j/openCypher language server";
    homepage = "https://github.com/neo4j/cypher-language-support";
    license = licenses.asl20;
    mainProgram = "cypher-language-server";
  };
}
