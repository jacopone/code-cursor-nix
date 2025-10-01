{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  makeWrapper,
  undmg,
}:

let
  pname = "cursor";
  version = "1.7.17";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/34881053400013f38e2354f1479c88c9067039a2/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-OsZiUXWKNLO8sUqielk0kap0DAkMY8OvWYO0KV3iads=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/34881053400013f38e2354f1479c88c9067039a2/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-jDUuns3IHE9WjOC4QB79QTFcocury//YH/pGkb/EYcQ=";
    };
    x86_64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/34881053400013f38e2354f1479c88c9067039a2/darwin/x64/Cursor-darwin-x64.dmg";
      hash = "sha256-KZfiJvMrb+KC8FwFhFJBueuxOsfJ7gUZonN+qUoqpP4=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/34881053400013f38e2354f1479c88c9067039a2/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-0WNrLhLQ/2ocpRh7fKv1+xqrckJl+F/WaP/KSY6Me00=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  appimageContents = appimageTools.extractType2 {
    inherit pname version;
    src = source;
  };
in
if stdenv.hostPlatform.isLinux then
  appimageTools.wrapType2 {
    inherit pname version;
    src = source;

    extraInstallCommands = ''
      # Install desktop file and icons
      install -Dm444 ${appimageContents}/cursor.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/cursor.desktop \
        --replace-fail 'Exec=cursor' 'Exec=${pname}'

      # Copy icon files
      for size in 16 32 48 64 128 256 512 1024; do
        if [ -f ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/cursor.png ]; then
          install -Dm444 ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/cursor.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/cursor.png
        fi
      done
    '';

    meta = with lib; {
      description = "AI-powered code editor built on VS Code";
      homepage = "https://cursor.com";
      changelog = "https://www.cursor.com/changelog";
      license = licenses.unfree;
      maintainers = [ ];
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      mainProgram = "cursor";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  }
else if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation {
    inherit pname version;
    src = source;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Cursor.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Cursor.app
      cp -R . $out/Applications/Cursor.app
      runHook postInstall
    '';

    meta = with lib; {
      description = "AI-powered code editor built on VS Code";
      homepage = "https://cursor.com";
      changelog = "https://www.cursor.com/changelog";
      license = licenses.unfree;
      maintainers = [ ];
      platforms = lib.platforms.darwin;
      mainProgram = "cursor";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  }
else
  throw "Unsupported platform: ${stdenv.hostPlatform.system}"
