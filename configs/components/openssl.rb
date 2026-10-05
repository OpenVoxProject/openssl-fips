component 'openssl' do |pkg, settings, platform|
  pkg.version '3.0.22'
  pkg.sha256sum '67ebca7e50d17383028045486653492195b83db95f8558709701bb47b5c1ef81'

  pkg.url "https://openssl.org/source/openssl-#{pkg.get_version}.tar.gz"

  #############
  # ENVIRONMENT
  #############

  # OpenSSL 3 accepts CFLAGS, etc environment variables (unlike 1.1.1)

  if platform.is_el? && platform.is_fips?
    pkg.build_requires 'perl-core'

    pkg.environment 'PATH', '$(PATH):/usr/local/bin'

    target = 'linux-x86_64'
  elsif platform.is_windows?
    pkg.build_requires 'strawberryperl'

    pkg.environment 'PATH', "$(shell cygpath -u #{settings[:gcc_bindir]}):$(PATH)"

    target = 'mingw64'
  else
    raise 'The openssl-fips component is only supported on RHEL and Windows'
  end

  pkg.environment 'CFLAGS', settings[:cflags]
  pkg.environment 'LDFLAGS', settings[:ldflags]

  ###########
  # CONFIGURE
  ###########

  configure_flags = [
    "--prefix=#{settings[:prefix]}",
    '--libdir=lib',
    "--openssldir=#{settings[:ssldir]}",
    'shared',
    target,
    'enable-fips'
  ]

  pkg.configure do
    ["./Configure #{configure_flags.join(' ')}"]
  end

  #######
  # BUILD
  #######

  pkg.build do
    [
      platform[:make]
    ]
  end

  #########
  # INSTALL
  #########

  pkg.install do
    [
      "#{platform[:make]} #{settings[:install_prefix]} install_fips",
      "rm #{settings[:fipsmodule_cnf]}"
    ]
  end
end
