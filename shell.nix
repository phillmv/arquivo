with import <nixpkgs> {};
let
  forego = pkgs.buildGoPackage rec {
    name = "forego-${version}";
    version = "20180216151118";

    goPackagePath = "github.com/ddollar/forego";

    src = pkgs.fetchFromGitHub {
      owner = "ddollar";
      repo = "forego";
      rev = "${version}";
      sha256 = "1xypm61b05vsq75807ax0q41z6jr438malrz9z7qkrh4nghmbiww";
    };

    buildFlags = "--tags release";
  };


  # define packagesto install with special handling for OSX
  basePackages = [
    forego
    python
    nodejs-12_x
    yarn
    gnumake
    gcc
    readline
    openssl
    zlib
    curl
    libiconv
    postgresql_11
    pkgconfig
    libxml2
    libxslt
    ruby
    zlib
    libiconv
    lzma
    redis
    git
    openssh
    sqlite
  ];

  inputs = if pkgs.system == "x86_64-darwin" then
              basePackages ++ [pkgs.darwin.apple_sdk.frameworks.CoreServices]
           else
              basePackages;


   localPath = ./. + "/local.nix";

   final = if builtins.pathExists localPath then
            inputs ++ (import localPath).inputs
           else
            inputs;

  # define shell startup command with special handling for OSX
  baseHooks = ''
    export PS1='\n\[\033[1;32m\][nix-shell:\w]($(git rev-parse --abbrev-ref HEAD))\$\[\033[0m\] '

    mkdir -p .nix-gems
    mkdir -p tmp/pids
    export GEM_HOME=$PWD/.nix-gems
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
    export PATH=$PWD/bin:$PATH
    echo "bundler install check..."
    gem list -i ^bundler$ -v 1.17.2 || gem install bundler --version=1.17.3 --no-document
    bundle config build.nokogiri --use-system-libraries
    bundle config --local path vendor/cache
    export DISABLE_SPRING=true
  '';

  hooks = if builtins.pathExists localPath then
            baseHooks + (import localPath).hooks
          else
            baseHooks;

in
  pkgs.stdenv.mkDerivation {
    name = "arquivo";
    buildInputs = final;
    shellHook = hooks;
    hardeningDisable = [ "all" ];
  }
