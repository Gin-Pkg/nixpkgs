{ lib
, stdenv
, fetchFromGitHub
, buildPackages
, pkg-config
, libusb-compat-0_1
, readline
, libewf
, perl
, zlib
, openssl
, libuv
, file
, libzip
, xxHash
, gtk2
, vte
, gtkdialog
, python3
, ruby
, lua
, capstone
, useX11 ? false
, rubyBindings ? false
, pythonBindings ? false
, luaBindings ? false
}:

let
  # FIXME: Compare revision with https://github.com/radareorg/radare2/blob/master/libr/asm/arch/arm/v35arm64/Makefile#L20
  arm64 = fetchFromGitHub {
    owner = "radareorg";
    repo = "vector35-arch-arm64";
    rev = "3c5eaba46dab72ecb7d5f5b865a13fdeee95b464";
    sha256 = "sha256-alcGEi+D8CptXzfznnuxQKCvU2mbzn2sQge5jSqLVpg=";
  };
in
stdenv.mkDerivation rec {
  pname = "radare2";
  version = "5.4.2";

  src = fetchFromGitHub {
    owner = "radare";
    repo = "radare2";
    rev = version;
    sha256 = "sha256-5GvJ7J+pAL8GIZ4Tv09wdGyihfMm1bUABhmf7ozQoxc=";
  };

  preBuild = ''
    cp -r ${arm64} libr/asm/arch/arm/v35arm64/arch-arm64
    chmod -R +w libr/asm/arch/arm/v35arm64/arch-arm64
  '';

  postFixup = lib.optionalString stdenv.isDarwin ''
    for file in $out/bin/rasm2 $out/bin/ragg2 $out/bin/rabin2 $out/lib/libr_asm.${version}.dylib; do
      install_name_tool -change libcapstone.4.dylib ${capstone}/lib/libcapstone.4.dylib $file
    done
  '';

  postInstall = ''
    install -D -m755 $src/binr/r2pm/r2pm $out/bin/r2pm
  '';

  WITHOUT_PULL = "1";
  makeFlags = [
    "GITTAP=${version}"
    "RANLIB=${stdenv.cc.bintools.bintools}/bin/${stdenv.cc.bintools.targetPrefix}ranlib"
    "CC=${stdenv.cc.targetPrefix}cc"
    "HOST_CC=${stdenv.cc.targetPrefix}cc"
  ];

  configureFlags = [
    "--with-sysmagic"
    "--with-syszip"
    "--with-sysxxhash"
    "--with-syscapstone"
    "--with-openssl"
  ];

  enableParallelBuilding = true;
  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    capstone
    file
    readline
    libusb-compat-0_1
    libewf
    perl
    zlib
    openssl
    libuv
  ] ++ lib.optional useX11 [ gtkdialog vte gtk2 ]
    ++ lib.optional rubyBindings [ ruby ]
    ++ lib.optional pythonBindings [ python3 ]
    ++ lib.optional luaBindings [ lua ];

  propagatedBuildInputs = [
    # radare2 exposes r_lib which depends on these libraries
    file # for its list of magic numbers (`libmagic`)
    libzip
    xxHash
  ];

  meta = with lib; {
    description = "unix-like reverse engineering framework and commandline tools";
    homepage = "https://radare.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ raskin makefu mic92 arkivm ];
    platforms = platforms.unix;
  };
}
