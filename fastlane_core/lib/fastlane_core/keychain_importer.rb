module FastlaneCore
  class KeychainImporter
    def self.import_file(path, keychain_path, keychain_password: "", certificate_password: "", output: FastlaneCore::Globals.verbose?)
      UI.user_error!("Could not find file '#{path}'") unless File.exist?(path)

      command = "security import #{path.shellescape} -k '#{keychain_path.shellescape}'"
      command << " -P #{certificate_password.shellescape}"
      command << " -T /usr/bin/codesign" # to not be asked for permission when running a tool like `gym`
      command << " -T /usr/bin/security"
      command << " &> /dev/null" unless output

      Helper.backticks(command, print: output)
      UI.user_error!("Failed to import #{path} into #{keychain_path}") unless $?.success?

      # When security supports partition lists, also add the partition IDs
      # See https://openradar.appspot.com/28524119
      if `security -h | grep set-key-partition-list`.length > 0
        command = "security set-key-partition-list"
        command << " -S apple-tool:,apple:"
        command << " -k \"#{keychain_password}\""
        command << " #{keychain_path.shellescape}"
        command << " &> /dev/null" unless output

        Helper.backticks(command, print: output)
        UI.user_error!("Failed to set-key-partition-list to #{keychain_path}") unless $?.success?
      end
    end
  end
end
