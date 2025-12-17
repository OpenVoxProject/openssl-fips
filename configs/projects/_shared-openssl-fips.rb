proj.version_from_git
proj.generate_archives true
proj.generate_packages false

proj.description 'OpenSSL FIPS module'
proj.license 'See components'
proj.vendor "Vox Pupuli <openvox@voxpupuli.org>"
  proj.homepage "https://voxpupuli.org"
  proj.identifier "org.voxpupuli"

if platform.is_windows?
    proj.setting(:company_id, "VoxPupuli")
    proj.setting(:pl_company_id, "PuppetLabs")
    proj.setting(:product_id, "OpenVox")
    proj.setting(:pl_product_id, "Puppet")
    proj.setting(:base_dir, "ProgramFiles64Folder")

    # We build for windows not in the final destination, but in the paths that correspond
    # to the directory ids expected by WIX. This will allow for a portable installation (ideally).
    proj.setting(:install_root, File.join("C:", proj.base_dir, proj.pl_company_id, proj.pl_product_id))
    proj.setting(:install_prefix, '')
else
    proj.setting(:install_root, "/opt/puppetlabs")
    proj.setting(:install_prefix, 'INSTALL_PREFIX=/')
end

# Projects that consume these shared settings must provide a prefix
proj.setting(:prefix, File.join(proj.install_root, prefix))
proj.setting(:bindir, File.join(proj.prefix, "bin"))
proj.setting(:libdir, File.join(proj.prefix, "lib"))
proj.setting(:ssldir, File.join(proj.prefix, "ssl"))
proj.setting(:includedir, File.join(proj.prefix, "include"))
proj.setting(:fipsmodule_cnf, File.join(proj.ssldir, 'fipsmodule.cnf'))

# Define default CFLAGS and LDFLAGS for most platforms, and then
# tweak or adjust them as needed.
#
if platform.is_windows?
    arch = platform.architecture == "x64" ? "64" : "32"
    proj.setting(:gcc_root, '/usr/x86_64-w64-mingw32/sys-root/mingw')
    proj.setting(:gcc_bindir, "#{proj.gcc_root}/bin")
    proj.setting(:tools_root, '/usr/x86_64-w64-mingw32/sys-root/mingw')
    # If tools_root ever differs from gcc_root again, add it back here.
    proj.setting(:cppflags, "-I#{proj.gcc_root}/include -I#{proj.gcc_root}/include/readline -I#{proj.includedir}")
    proj.setting(:cflags, proj.cppflags)
    # nxcompat: enable DEP
    # dynamicbase: enable ASLR
    proj.setting(:ldflags, "-L#{proj.tools_root}/lib -L#{proj.gcc_root}/lib -L#{proj.libdir} -Wl,--nxcompat -Wl,--dynamicbase")

    proj.setting(:cygwin, "nodosfilewarning winsymlinks:native")
else
    proj.setting(:cppflags, "-I#{proj.includedir} -D_FORTIFY_SOURCE=2")
    proj.setting(:cflags, "#{proj.cppflags} -fstack-protector-strong -fno-plt -O2")
    # -z,relro: partial read-only relocations
    proj.setting(:ldflags, "-L#{proj.libdir} -Wl,-rpath=#{proj.libdir},-z,relro,-z,now")
end

proj.directory proj.libdir
proj.directory proj.ssldir

proj.component "openssl"
