{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "lazygit";
  version = "0.31.3";

  src = fetchFromGitHub {
    owner = "jesseduffield";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-CgWN7xfWX0aSwNAPt2UDftyD0CbQQSUY6SMlyP9TSjc=";
  };

  vendorSha256 = null;
  subPackages = [ "." ];

  ldflags = [ "-X main.version=${version}" "-X main.buildSource=nix" ];

  meta = with lib; {
    description = "Simple terminal UI for git commands";
    homepage = "https://github.com/jesseduffield/lazygit";
    changelog = "https://github.com/jesseduffield/lazygit/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ fpletz equirosa Br1ght0ne ];
  };
}
