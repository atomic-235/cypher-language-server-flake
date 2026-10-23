{
  lib,
  buildNpmPackage,
  fetchurl,
}:

let
  data = builtins.fromJSON (builtins.readFile ./version.json);
in
buildNpmPackage {
  pname = "cypher-language-server";
  version = data.version;

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
