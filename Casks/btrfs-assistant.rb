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

  binary "install/bin/btrfs-assistant"
  binary "install/bin/btrfs-assistant-bin"
  binary "install/bin/btrfs-assistant-launcher"
  artifact "install/share/applications/btrfs-assistant.desktop",
           target: "#{Dir.home}/.local/share/applications/btrfs-assistant.desktop"
  artifact "install/share/icons/hicolor/scalable/apps/btrfs-assistant.svg",
           target: "#{Dir.home}/.local/share/icons/hicolor/scalable/apps/btrfs-assistant.svg"
  artifact "install/share/polkit-1/actions/org.btrfs-assistant.pkexec.policy",
           target: "#{HOMEBREW_PREFIX}/etc/polkit-1/actions/org.btrfs-assistant.pkexec.policy"

  preflight do
    # Build and install the application
    system_command "cmake",
                   args: ["-B", "#{staged_path}/build",
                          "-S", "#{staged_path}/btrfs-assistant-#{version}",
                          "-DCMAKE_INSTALL_PREFIX=#{staged_path}/install",
                          "-DCMAKE_BUILD_TYPE=Release"]
    system_command "cmake",
                   args: ["--build", "#{staged_path}/build"]
    system_command "cmake",
                   args: ["--install", "#{staged_path}/build"]

    # Create necessary directories
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/scalable/apps"
    FileUtils.mkdir_p "#{HOMEBREW_PREFIX}/etc/polkit-1/actions"

    # Fix desktop file to use Homebrew binary path
    desktop_file = "#{staged_path}/install/share/applications/btrfs-assistant.desktop"
    if File.exist?(desktop_file)
      text = File.read(desktop_file)
      new_contents = text.gsub(%r{Exec=/usr/bin/btrfs-assistant}, "Exec=#{HOMEBREW_PREFIX}/bin/btrfs-assistant")
                         .gsub(%r{Exec=btrfs-assistant}, "Exec=#{HOMEBREW_PREFIX}/bin/btrfs-assistant")
      File.write(desktop_file, new_contents)
    end
  end

  postflight do
    # Ensure config file exists
    config_file = "/etc/btrfs-assistant.conf"
    unless File.exist?(config_file)
      system "sudo", "mkdir", "-p", "/etc"
      system "sudo", "touch", config_file
    end
  end

  zap trash: [
    "~/.config/btrfs-assistant",
    "/etc/btrfs-assistant.conf",
  ]
end
