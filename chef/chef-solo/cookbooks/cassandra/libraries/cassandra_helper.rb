module CassandraHelper
  def self.get_riptano_repo_pkg_info(os, base_ver, arch)
    # Riptano Repo Packages
    # http://rpm.riptano.com/EL/5/i386/        riptano-release-5-1.el5.noarch.rpm
    # http://rpm.riptano.com/EL/5/x86_64/      riptano-release-5-1.el5.noarch.rpm
    # http://rpm.riptano.com/EL/6/i386/        riptano-release-5-1.el6.noarch.rpm
    # http://rpm.riptano.com/EL/6/x86_64/      riptano-release-5-1.el6.noarch.rpm
    # 
    # http://rpm.riptano.com/Fedora/12/i386/   riptano-release-5-1.fc12.noarch.rpm
    # http://rpm.riptano.com/Fedora/12/x86_64/ riptano-release-5-1.fc12.noarch.rpm
    # http://rpm.riptano.com/Fedora/13/i386/   riptano-release-5-1.fc13.noarch.rpm
    # http://rpm.riptano.com/Fedora/13/x86_64/ riptano-release-5-1.fc13.noarch.rpm
    # http://rpm.riptano.com/Fedora/14/i386/   riptano-release-5-1.fc14.noarch.rpm 
    # http://rpm.riptano.com/Fedora/14/x86_64/ riptano-release-5-1.fc14.noarch.rpm 
    repo_pkg_version = "5-1"

    if os == "fedora"
      arch = 'i386' if arch == 'i686'
      distro_dir = "fedora"
      distro_ver = "fc#{base_ver}"
    else
      distro_dir = "EL" 
      distro_ver = "el#{base_ver}"
    end
  
    rpm_filename = "riptano-release-#{repo_pkg_version}.#{distro_ver}.noarch.rpm"

    { :filename => rpm_filename,
      :url => "http://rpm.riptano.com/#{distro_dir}/#{base_ver}/#{arch}/#{rpm_filename}" }
  end
end
