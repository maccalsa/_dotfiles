{
  description = "Modern Laravel Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Change this to easily switch between PHP versions (e.g., "php83" or "php84")
        phpVersion = pkgs.php83;
        phpExtensions = pkgs.php83Extensions;
        phpPackages = pkgs.php83Packages;
      in {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = [
              phpVersion
              pkgs.nodejs_20
              pkgs.sqlite
              pkgs.redis
              pkgs.nginx
              pkgs.mariadb
              pkgs.laravel

              # PHP packages and extensions
              phpPackages.composer
              phpExtensions.imagick
              phpExtensions.xdebug
              phpExtensions.pdo_mysql
              phpExtensions.pdo_sqlite
              phpExtensions.xmlreader  # Fixes XMLReader error
              phpExtensions.xmlwriter  # Fixes XMLWriter error
              phpExtensions.zip        # Fixes ZIP error
              phpExtensions.zlib       # Fixes ZLIB error
              phpExtensions.mbstring   # REQUIRED by Laravel
              phpExtensions.iconv      # REQUIRED by Laravel
            ];

            shellHook = ''
              echo "Laravel development environment ready!"
              echo "Using PHP version: $(php -v | head -n 1)"
              echo "Run 'composer install' to set up dependencies."
              echo "Run 'npm install' to set up frontend dependencies."
            '';
          };
        };
      }
    );
}