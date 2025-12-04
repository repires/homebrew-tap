cask "btrfs-assistant" do
  version "2.2"
  sha256 "cf478b7a5673a456b3aa09df2a875aae8a023511a14ef901970666b93c28ebb9"

  url "https://gitlab.com/btrfs-assistant/btrfs-assistant/-/archive/#{version}/btrfs-assistant-#{version}.tar.gz"
  name "Btrfs Assistant"
  desc "Application for managing BTRFS subvolumes and Snapper snapshots"
  homepage "https://gitlab.com/btrfs-assistant/btrfs-assistant"

  livecheck do
    url "https://gitlab.com/api/v4/projects/btrfs-assistant%2Fbtrfs-assistant/releases"
    strategy :json do |json|
      json.map { |release| release["tag_name"] }
    end
  end

  binary "btrfs-assistant-#{version}/build/src/btrfs-assistant"
  binary "btrfs-assistant-#{version}/build/src/btrfs-assistant-launcher"
  artifact "btrfs-assistant-#{version}/build/src/btrfs-assistant.desktop",
           target: "#{Dir.home}/.local/share/applications/btrfs-assistant.desktop"

  preflight do
    # Build the application
    system_command "sed",
                   args: ["-e", "s/-Werror//", "-i", "#{staged_path}/btrfs-assistant-#{version}/src/CMakeLists.txt"]
    system_command "cmake",
                   args: ["-B", "#{staged_path}/btrfs-assistant-#{version}/build",
                          "-S", "#{staged_path}/btrfs-assistant-#{version}",
                          "-DCMAKE_INSTALL_PREFIX=/usr",
                          "-DCMAKE_BUILD_TYPE=Release"]
    system_command "cmake",
                   args: ["--build", "#{staged_path}/btrfs-assistant-#{version}/build"]

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    File.write("#{staged_path}/btrfs-assistant-#{version}/build/src/btrfs-assistant.desktop", <<~EOS)
      [Desktop Entry]
      Name=Btrfs Assistant
      Comment=GUI management tool for Btrfs filesystems
      GenericName=Btrfs Manager
      Exec=#{HOMEBREW_PREFIX}/bin/btrfs-assistant
      Icon=btrfs-assistant
      Type=Application
      Categories=System;FileTools;Filesystem;
      Keywords=btrfs;filesystem;snapshot;subvolume;
      Terminal=false
    EOS
  end

  zap trash: [
    "~/.config/btrfs-assistant",
    "/etc/btrfs-assistant.conf",
  ]
end
